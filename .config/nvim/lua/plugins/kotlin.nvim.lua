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
      -- -- Optional: Specify a custom Java path to run the server
      -- jre_path = os.getenv("JDK21"),
      -- Optional: Specify additional JVM arguments
      jvm_args = {
        "-Xmx4g",
      },
    })
  end,
}
