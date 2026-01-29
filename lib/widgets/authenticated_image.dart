import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class AuthenticatedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AuthenticatedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  State<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends State<AuthenticatedImage> {
  Uint8List? _imageData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final user = await AuthService.getCurrentUser();
      final headers = <String, String>{};
      
      if (user != null && user.token != null) {
        headers['Authorization'] = 'Bearer ${user.token}';
      }

      final response = await http.get(
        Uri.parse(widget.imageUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        setState(() {
          _imageData = response.bodyBytes;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ?? 
        Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
    }

    if (_hasError || _imageData == null) {
      return widget.errorWidget ??
        Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[300],
          child: const Icon(
            Icons.broken_image,
            color: Colors.grey,
            size: 48,
          ),
        );
    }

    return Image.memory(
      _imageData!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}
