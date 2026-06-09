/** @type {import("next").NextConfig} */
const nextConfig = {
  images: {
    domains: [
      "localhost",
      "cf.shopee.com.br",
      "http2.mlstatic.com",
      "m.media-amazon.com",
      "img.ltwebstatic.com",
    ],
  },
};
module.exports = nextConfig;
