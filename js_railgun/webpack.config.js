const path = require('path');
const webpack = require('webpack');

module.exports = {
  entry: './dist/index.js',
  mode: 'production',
  module: {
    rules: [],
  },
  resolve: {
    extensions: ['.tsx', '.ts', '.js'],
    fallback: {
      "crypto": require.resolve("crypto-browserify"),
      "stream": require.resolve("stream-browserify"),
      "assert": false,
      "http": false,
      "https": false,
      "os": false,
      "url": false,
      "zlib": false,
      "path": false,
      "vm": false
    }
  },
  output: {
    filename: 'railgun_bundle.js',
    path: path.resolve(__dirname, 'dist'),
    library: 'VeilRailgun',
    libraryTarget: 'window',
  },
  plugins: [
    new webpack.ProvidePlugin({
      process: 'process/browser',
      Buffer: ['buffer', 'Buffer'],
    }),
  ]
};
