import 'package:flutter/material.dart';

class TextInputWidget extends StatefulWidget {
  final String question;
  final String? context;
  final Function(String) onAnswerChanged;
  final String? placeholder;

  const TextInputWidget({
    super.key,
    required this.question,
    this.context,
    required this.onAnswerChanged,
    this.placeholder,
  });

  @override
  State<TextInputWidget> createState() => _TextInputWidgetState();
}

class _TextInputWidgetState extends State<TextInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      widget.onAnswerChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[900]!, Colors.purple[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit, color: Colors.purple[300], size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Text Response',
                    style: TextStyle(
                      color: Colors.purple[300],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.question,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              if (widget.context != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.context!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  _focusNode.hasFocus ? Colors.purple[400]! : Colors.grey[600]!,
              width: 2,
            ),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: 4,
            minLines: 3,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: widget.placeholder ?? 'Type your answer here...',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (value) {
              setState(() {}); // Trigger rebuild for border color
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.yellow[600], size: 16),
            const SizedBox(width: 8),
            Text(
              'Take your time and be thoughtful with your response',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
