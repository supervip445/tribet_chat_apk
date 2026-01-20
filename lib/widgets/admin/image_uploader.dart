import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';

class ImageUploader extends StatefulWidget {
  final List<File> images;
  final Function(List<File>) onImagesChange;
  final int maxImages;
  final Function(int, double)? onUploadProgress;
  final bool enableCrop;

  const ImageUploader({
    super.key,
    required this.images,
    required this.onImagesChange,
    this.maxImages = 10,
    this.onUploadProgress,
    this.enableCrop = true,
  });

  @override
  State<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  final ImagePicker _picker = ImagePicker();
  final Map<int, double> _progressMap = {};
  final Map<int, String> _stageMap = {};

  Future<void> _pickImages() async {
    if (widget.images.length >= widget.maxImages) {
      _showSnackBar('Maximum ${widget.maxImages} images allowed');
      return;
    }

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isEmpty) return;

      final remainingSlots = widget.maxImages - widget.images.length;
      final filesToProcess = pickedFiles.take(remainingSlots).toList();

      for (int i = 0; i < filesToProcess.length; i++) {
        final xFile = filesToProcess[i];
        final index = widget.images.length + i;
        
        setState(() {
          _stageMap[index] = 'compressing';
          _progressMap[index] = 0;
        });

        // Compress image
        final compressedFile = await _compressImage(xFile.path, index);
        
        File? finalFile;
        
        if (widget.enableCrop) {
          setState(() {
            _stageMap[index] = 'cropping';
            _progressMap[index] = 50;
          });

          // Crop image
          finalFile = await _cropImage(compressedFile);
        } else {
          // Skip cropping, use compressed file directly
          finalFile = compressedFile;
        }
        
        if (finalFile != null) {
          setState(() {
            _stageMap[index] = 'ready';
            _progressMap[index] = 100;
            widget.images.add(finalFile!);
          });
          widget.onImagesChange([...widget.images]);
        }
      }
    } catch (e) {
      _showSnackBar('Error picking images: $e');
    }
  }

  Future<File> _compressImage(String path, int index) async {
    final file = File(path);
    final targetPath = '${file.parent.path}/compressed_${file.path.split('/').last}';
    
    final result = await FlutterImageCompress.compressAndGetFile(
      path,
      targetPath,
      quality: 85,
      minWidth: 1920,
      minHeight: 1080,
    );

    if (result != null) {
      setState(() {
        _progressMap[index] = 50;
      });
      return File(result.path);
    }
    return file;
  }

  Future<File?> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.amber[600]!,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
        ),
      ],
    );

    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return imageFile;
  }

  void _removeImage(int index) {
    setState(() {
      widget.images.removeAt(index);
      _progressMap.remove(index);
      _stageMap.remove(index);
    });
    widget.onImagesChange([...widget.images]);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: Text('Add Images (${widget.images.length}/${widget.maxImages})'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[600],
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        if (widget.images.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'No images selected',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: List.generate(widget.images.length, (index) {
              final image = widget.images[index];
              final progress = _progressMap[index] ?? 100;
              final stage = _stageMap[index] ?? 'ready';

              return Stack(
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (stage != 'ready')
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              stage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${progress.toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => _removeImage(index),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.all(4),
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
      ],
    );
  }
}

