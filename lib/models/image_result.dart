class ImageResult {
  final String? path;
  final String? error;

  ImageResult({this.path, this.error});

  bool get success => path != null && path!.isNotEmpty;
}
