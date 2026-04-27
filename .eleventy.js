module.exports = function(eleventyConfig) {
  eleventyConfig.addPassthroughCopy("index.html");
  eleventyConfig.addPassthroughCopy("aviso-legal.html");
  eleventyConfig.addPassthroughCopy("privacidad.html");
  eleventyConfig.addPassthroughCopy("incidencias.html");
  eleventyConfig.addPassthroughCopy("robots.txt");
  eleventyConfig.addPassthroughCopy("llms.txt");
  eleventyConfig.addPassthroughCopy("d75eac395db864420f8f0401b9277586.txt");
  eleventyConfig.addPassthroughCopy("fonts");
  eleventyConfig.addPassthroughCopy("icons");
  eleventyConfig.addPassthroughCopy("Media");
  eleventyConfig.addPassthroughCopy("assets");
  eleventyConfig.addPassthroughCopy("macbook_laptop.glb");
  eleventyConfig.addPassthroughCopy("videonuevo_dashboard.mp4");

  eleventyConfig.addFilter("dateES", (d) => {
    return new Date(d).toLocaleDateString("es-ES", {
      day: "numeric", month: "long", year: "numeric"
    });
  });

  eleventyConfig.addFilter("isoDate", (d) => {
    return new Date(d).toISOString().split("T")[0];
  });

  return {
    dir: {
      input: ".",
      output: "_site",
      includes: "_includes",
      data: "_data"
    },
    markdownTemplateEngine: "njk",
    htmlTemplateEngine: "njk"
  };
};
