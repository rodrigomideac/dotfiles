// niri-cursor-pos — print where the mouse pointer is.
//
// Wayland deliberately gives no client the global pointer position, and niri's
// IPC has no query for it either (`pick-window` and `pick-color` both need a
// click). The one thing a client *is* told is where the pointer sits inside its
// own surfaces: wl_pointer.enter carries surface-local coordinates, and the
// compositor sends it the moment a surface appears under the pointer — no
// motion and no click required.
//
// So: map an invisible fullscreen wlr-layer-shell surface on every output, wait
// for the enter event, print the coordinates it carries, and unmap. The surface
// lives for a few milliseconds on the overlay layer with no keyboard
// interactivity, so nothing is drawn and nothing loses focus.
//
// Because the surface is anchored to all four edges with exclusive_zone -1 it
// covers the whole output, which makes surface-local coordinates identical to
// output-local ones — the space niri's own window geometry uses.
//
// The enter event normally arrives in a millisecond or two, but niri defers
// pointer-focus updates while it animates a window open — measured at ~335 ms.
// That is exactly the moment this gets called to place a window that just
// appeared, hence the generous default timeout: it costs nothing when the event
// arrives, since the wait ends on the event and not on the clock.
//
//     $ niri-cursor-pos
//     1233 604 DP-3
//     $ niri-cursor-pos --json
//     {"x":1233,"y":604,"output":"DP-3","global_x":1233,"global_y":604}
//
// Exit status: 0 on success, 1 if the pointer was not reported before the
// timeout (something else holds a pointer grab), 2 on a setup error.
//
// Built and installed by tools/build.sh — see `make tools` in the repo root.

#define _GNU_SOURCE

#include <errno.h>
#include <poll.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

#include <wayland-client.h>

#include "wlr-layer-shell-unstable-v1-client-protocol.h"

#define NAMESPACE "niri-cursor-pos"

struct output {
	struct wl_output *wl;
	uint32_t global;
	char *name;
	int32_t x, y; // logical position of the output in the compositor space
	struct wl_surface *surface;
	struct zwlr_layer_surface_v1 *layer;
	int32_t width, height;
	struct wl_buffer *buffer;
	struct output *next;
};

static struct wl_display *display;
static struct wl_compositor *compositor;
static struct wl_shm *shm;
static struct zwlr_layer_shell_v1 *layer_shell;
static struct wl_seat *seat;
static struct wl_pointer *pointer;
static struct output *outputs;

static bool found;      // the pointer reported its position
static double found_x, found_y;
static struct output *found_output;

static void die(const char *msg) {
	fprintf(stderr, "niri-cursor-pos: %s\n", msg);
	exit(2);
}

static int64_t now_ms(void) {
	struct timespec ts;
	clock_gettime(CLOCK_MONOTONIC, &ts);
	return (int64_t)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

// ---------------------------------------------------------------- shm buffer

// A fully transparent ARGB buffer. The surface has to be mapped to receive
// pointer input, and a mapped surface needs a buffer; zeroed memory is already
// the transparent pixel, so nothing has to be drawn into it.
static struct wl_buffer *make_transparent_buffer(int32_t width, int32_t height) {
	int32_t stride = width * 4;
	size_t size = (size_t)stride * height;

	int fd = memfd_create(NAMESPACE, MFD_CLOEXEC | MFD_ALLOW_SEALING);
	if (fd < 0) return NULL;
	if (ftruncate(fd, size) < 0) {
		close(fd);
		return NULL;
	}
	// Never mapped by us: the compositor reads it, and it is already zeroed.
	struct wl_shm_pool *pool = wl_shm_create_pool(shm, fd, size);
	close(fd);
	if (!pool) return NULL;

	struct wl_buffer *buffer = wl_shm_pool_create_buffer(
		pool, 0, width, height, stride, WL_SHM_FORMAT_ARGB8888);
	wl_shm_pool_destroy(pool);
	return buffer;
}

// -------------------------------------------------------------- layer surface

static void layer_configure(void *data, struct zwlr_layer_surface_v1 *layer,
			    uint32_t serial, uint32_t width, uint32_t height) {
	struct output *out = data;
	zwlr_layer_surface_v1_ack_configure(layer, serial);

	if (width == 0 || height == 0) return;
	if (out->buffer && out->width == (int32_t)width && out->height == (int32_t)height) return;

	out->width = width;
	out->height = height;
	if (out->buffer) wl_buffer_destroy(out->buffer);
	out->buffer = make_transparent_buffer(width, height);
	if (!out->buffer) die("cannot allocate a shm buffer");

	wl_surface_attach(out->surface, out->buffer, 0, 0);
	wl_surface_damage_buffer(out->surface, 0, 0, width, height);
	wl_surface_commit(out->surface);
}

static void layer_closed(void *data, struct zwlr_layer_surface_v1 *layer) {
	(void)data;
	(void)layer;
}

static const struct zwlr_layer_surface_v1_listener layer_listener = {
	.configure = layer_configure,
	.closed = layer_closed,
};

static void open_surface(struct output *out) {
	out->surface = wl_compositor_create_surface(compositor);
	if (!out->surface) die("cannot create a surface");

	// Nothing is painted, so tell the compositor no pixel is opaque. The input
	// region is left at its default (the whole buffer), which is the point of
	// the exercise: it is what makes the pointer enter this surface.
	struct wl_region *empty = wl_compositor_create_region(compositor);
	wl_surface_set_opaque_region(out->surface, empty);
	wl_region_destroy(empty);

	out->layer = zwlr_layer_shell_v1_get_layer_surface(
		layer_shell, out->surface, out->wl,
		ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY, NAMESPACE);
	if (!out->layer) die("cannot create a layer surface");

	zwlr_layer_surface_v1_add_listener(out->layer, &layer_listener, out);
	// All four anchors plus a negative exclusive zone: the full output,
	// ignoring the space waybar and friends reserve, so surface-local
	// coordinates are output-local coordinates.
	zwlr_layer_surface_v1_set_anchor(out->layer,
		ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP | ZWLR_LAYER_SURFACE_V1_ANCHOR_BOTTOM |
		ZWLR_LAYER_SURFACE_V1_ANCHOR_LEFT | ZWLR_LAYER_SURFACE_V1_ANCHOR_RIGHT);
	zwlr_layer_surface_v1_set_exclusive_zone(out->layer, -1);
	zwlr_layer_surface_v1_set_keyboard_interactivity(
		out->layer, ZWLR_LAYER_SURFACE_V1_KEYBOARD_INTERACTIVITY_NONE);
	wl_surface_commit(out->surface);
}

// -------------------------------------------------------------------- pointer

static void pointer_enter(void *data, struct wl_pointer *wl_pointer, uint32_t serial,
			  struct wl_surface *surface, wl_fixed_t sx, wl_fixed_t sy) {
	(void)data;
	(void)wl_pointer;
	(void)serial;
	if (found) return;

	for (struct output *out = outputs; out; out = out->next) {
		if (out->surface != surface) continue;
		found_x = wl_fixed_to_double(sx);
		found_y = wl_fixed_to_double(sy);
		found_output = out;
		found = true;
		return;
	}
}

static void pointer_leave(void *data, struct wl_pointer *p, uint32_t serial,
			  struct wl_surface *surface) {
	(void)data; (void)p; (void)serial; (void)surface;
}
static void pointer_motion(void *data, struct wl_pointer *p, uint32_t time,
			   wl_fixed_t sx, wl_fixed_t sy) {
	(void)data; (void)p; (void)time; (void)sx; (void)sy;
}
static void pointer_button(void *data, struct wl_pointer *p, uint32_t serial,
			   uint32_t time, uint32_t button, uint32_t state) {
	(void)data; (void)p; (void)serial; (void)time; (void)button; (void)state;
}
static void pointer_axis(void *data, struct wl_pointer *p, uint32_t time,
			 uint32_t axis, wl_fixed_t value) {
	(void)data; (void)p; (void)time; (void)axis; (void)value;
}
// wl_pointer v5 splits scrolling into these and groups every event into a
// frame. libwayland aborts on a NULL listener slot for any event the bound
// version can send, so all of them need a stub even though none is read.
static void pointer_frame(void *data, struct wl_pointer *p) {
	(void)data; (void)p;
}
static void pointer_axis_source(void *data, struct wl_pointer *p, uint32_t source) {
	(void)data; (void)p; (void)source;
}
static void pointer_axis_stop(void *data, struct wl_pointer *p, uint32_t time, uint32_t axis) {
	(void)data; (void)p; (void)time; (void)axis;
}
static void pointer_axis_discrete(void *data, struct wl_pointer *p, uint32_t axis,
				  int32_t discrete) {
	(void)data; (void)p; (void)axis; (void)discrete;
}

static const struct wl_pointer_listener pointer_listener = {
	.enter = pointer_enter,
	.leave = pointer_leave,
	.motion = pointer_motion,
	.button = pointer_button,
	.axis = pointer_axis,
	.frame = pointer_frame,
	.axis_source = pointer_axis_source,
	.axis_stop = pointer_axis_stop,
	.axis_discrete = pointer_axis_discrete,
};

static void seat_capabilities(void *data, struct wl_seat *wl_seat, uint32_t caps) {
	(void)data;
	if ((caps & WL_SEAT_CAPABILITY_POINTER) && !pointer) {
		pointer = wl_seat_get_pointer(wl_seat);
		wl_pointer_add_listener(pointer, &pointer_listener, NULL);
	}
}

static void seat_name(void *data, struct wl_seat *wl_seat, const char *name) {
	(void)data; (void)wl_seat; (void)name;
}

static const struct wl_seat_listener seat_listener = {
	.capabilities = seat_capabilities,
	.name = seat_name,
};

// --------------------------------------------------------------------- output

static void output_geometry(void *data, struct wl_output *wl_output, int32_t x, int32_t y,
			    int32_t pw, int32_t ph, int32_t subpixel,
			    const char *make, const char *model, int32_t transform) {
	(void)wl_output; (void)pw; (void)ph; (void)subpixel; (void)make; (void)model; (void)transform;
	struct output *out = data;
	out->x = x;
	out->y = y;
}
static void output_mode(void *data, struct wl_output *o, uint32_t flags,
			int32_t w, int32_t h, int32_t refresh) {
	(void)data; (void)o; (void)flags; (void)w; (void)h; (void)refresh;
}
static void output_done(void *data, struct wl_output *o) { (void)data; (void)o; }
static void output_scale(void *data, struct wl_output *o, int32_t factor) {
	(void)data; (void)o; (void)factor;
}
static void output_name(void *data, struct wl_output *o, const char *name) {
	(void)o;
	struct output *out = data;
	free(out->name);
	out->name = strdup(name);
}
static void output_description(void *data, struct wl_output *o, const char *d) {
	(void)data; (void)o; (void)d;
}

static const struct wl_output_listener output_listener = {
	.geometry = output_geometry,
	.mode = output_mode,
	.done = output_done,
	.scale = output_scale,
	.name = output_name,
	.description = output_description,
};

// ------------------------------------------------------------------- registry

static void registry_global(void *data, struct wl_registry *registry, uint32_t name,
			    const char *interface, uint32_t version) {
	(void)data;
	if (strcmp(interface, wl_compositor_interface.name) == 0) {
		compositor = wl_registry_bind(registry, name, &wl_compositor_interface,
					      version < 4 ? version : 4);
	} else if (strcmp(interface, wl_shm_interface.name) == 0) {
		shm = wl_registry_bind(registry, name, &wl_shm_interface, 1);
	} else if (strcmp(interface, zwlr_layer_shell_v1_interface.name) == 0) {
		layer_shell = wl_registry_bind(registry, name, &zwlr_layer_shell_v1_interface,
					       version < 2 ? version : 2);
	} else if (strcmp(interface, wl_seat_interface.name) == 0) {
		if (seat) return; // one seat is enough; niri only has "seat0"
		seat = wl_registry_bind(registry, name, &wl_seat_interface,
					version < 5 ? version : 5);
		wl_seat_add_listener(seat, &seat_listener, NULL);
	} else if (strcmp(interface, wl_output_interface.name) == 0) {
		struct output *out = calloc(1, sizeof(*out));
		if (!out) die("out of memory");
		out->global = name;
		// Version 4 is what carries wl_output.name ("DP-3"), which is how the
		// caller matches this against `niri msg outputs`.
		out->wl = wl_registry_bind(registry, name, &wl_output_interface,
					   version < 4 ? version : 4);
		wl_output_add_listener(out->wl, &output_listener, out);
		out->next = outputs;
		outputs = out;
	}
}

static void registry_global_remove(void *data, struct wl_registry *r, uint32_t name) {
	(void)data; (void)r; (void)name;
}

static const struct wl_registry_listener registry_listener = {
	.global = registry_global,
	.global_remove = registry_global_remove,
};

// ----------------------------------------------------------------------- main

static void usage(FILE *f) {
	fprintf(f,
		"usage: niri-cursor-pos [--json] [--global] [--timeout MS]\n"
		"\n"
		"  Prints \"X Y OUTPUT\" — the pointer position in output-local logical\n"
		"  pixels, the same space niri reports window geometry in.\n"
		"\n"
		"  --json         print {\"x\":..,\"y\":..,\"output\":..,\"global_x\":..,\"global_y\":..}\n"
		"  --global       print compositor-global coordinates instead of output-local\n"
		"  --timeout MS   how long to wait for the pointer (default 2000)\n");
}

int main(int argc, char **argv) {
	bool json = false, global = false;
	int timeout_ms = 2000;

	for (int i = 1; i < argc; i++) {
		if (strcmp(argv[i], "--json") == 0) {
			json = true;
		} else if (strcmp(argv[i], "--global") == 0) {
			global = true;
		} else if (strcmp(argv[i], "--timeout") == 0 && i + 1 < argc) {
			timeout_ms = atoi(argv[++i]);
			if (timeout_ms <= 0) die("--timeout must be a positive number of ms");
		} else if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0) {
			usage(stdout);
			return 0;
		} else {
			usage(stderr);
			return 2;
		}
	}

	display = wl_display_connect(NULL);
	if (!display) die("cannot connect to the Wayland display (is WAYLAND_DISPLAY set?)");

	struct wl_registry *registry = wl_display_get_registry(display);
	wl_registry_add_listener(registry, &registry_listener, NULL);
	// First round trip collects the globals, the second the events they emit
	// (output names and geometry, seat capabilities).
	wl_display_roundtrip(display);
	wl_display_roundtrip(display);

	if (!compositor) die("the compositor does not advertise wl_compositor");
	if (!shm) die("the compositor does not advertise wl_shm");
	if (!layer_shell) die("the compositor does not support wlr-layer-shell");
	if (!pointer) die("the seat has no pointer");
	if (!outputs) die("no outputs");

	for (struct output *out = outputs; out; out = out->next) open_surface(out);

	int64_t deadline = now_ms() + timeout_ms;
	while (!found) {
		while (wl_display_prepare_read(display) != 0) {
			if (wl_display_dispatch_pending(display) < 0) die("connection lost");
		}
		if (wl_display_flush(display) < 0 && errno != EAGAIN) {
			wl_display_cancel_read(display);
			die("connection lost");
		}

		int remaining = (int)(deadline - now_ms());
		if (remaining <= 0) {
			wl_display_cancel_read(display);
			break;
		}

		struct pollfd pfd = {.fd = wl_display_get_fd(display), .events = POLLIN};
		int n = poll(&pfd, 1, remaining);
		if (n > 0) {
			wl_display_read_events(display);
			if (wl_display_dispatch_pending(display) < 0) die("connection lost");
		} else {
			wl_display_cancel_read(display);
			if (n == 0) break;          // timed out
			if (errno == EINTR) continue;
			die("poll failed");
		}
	}

	// Take the surfaces down before printing, so the caller's next action
	// (moving a window under the pointer, say) never races the overlay.
	for (struct output *out = outputs; out; out = out->next) {
		if (out->layer) zwlr_layer_surface_v1_destroy(out->layer);
		if (out->surface) wl_surface_destroy(out->surface);
	}
	wl_display_roundtrip(display);

	if (!found) {
		fprintf(stderr, "niri-cursor-pos: the pointer was not reported within %d ms "
				"(something else may hold a pointer grab)\n", timeout_ms);
		return 1;
	}

	int x = (int)found_x, y = (int)found_y;
	int gx = x + found_output->x, gy = y + found_output->y;
	const char *name = found_output->name ? found_output->name : "?";

	if (json) {
		printf("{\"x\":%d,\"y\":%d,\"output\":\"%s\",\"global_x\":%d,\"global_y\":%d}\n",
		       x, y, name, gx, gy);
	} else if (global) {
		printf("%d %d %s\n", gx, gy, name);
	} else {
		printf("%d %d %s\n", x, y, name);
	}
	return 0;
}
