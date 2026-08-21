const path = require('path');
const webpack = require('webpack');

module.exports = {
  entry: './src/index.js',
  output: {
    filename: 'prover.bundle.js',
    path: path.resolve(__dirname, 'dist'),
    library: 'VeilProver',
    libraryTarget: 'window'
  },
  resolve: {
    fallback: {
      "path": require.resolve("path-browserify"),
      "crypto": require.resolve("crypto-browserify"),
      "stream": require.resolve("stream-browserify"),
      "fs": false,
      "os": require.resolve("os-browserify/browser"),
      "vm": false,
      "url": false,
      "worker_threads": false,
      "tty": false,
      "child_process": false,
      "perf_hooks": false,
    }
  },
  plugins: [
    new webpack.ProvidePlugin({
      Buffer: ['buffer', 'Buffer'],
      process: 'process/browser',
    }),
  ],
  experiments: {
    asyncWebAssembly: true,
  },
  mode: 'production',
};
