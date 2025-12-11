return {
  "AlexandrosAlexiou/kotlin.nvim",
  ft = { "kotlin" },
  dependencies = { "mason.nvim", "mason-lspconfig.nvim", "oil.nvim" },
  config = function()
    require("kotlin").setup({
      -- Optional: Specify root markers for multi-module projects
      root_markers = {
        "gradlew",
        ".git",
        "mvnw",
        "settings.gradle",
      },
      -- Optional: Specify a custom Java path to run the server
      jre_path = "/home/rodrigo/.local/share/mise/installs/java/21.0.2",
      -- Optional: Specify additional JVM arguments
      jvm_args = {
        "-Xmx8g",
      },
    })
  end,
}
