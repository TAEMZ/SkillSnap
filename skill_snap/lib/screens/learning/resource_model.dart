enum ResourceType { course, video, article, documentation }

class ResourceLink {
  final String name;
  final ResourceType type;
  final String? url; // Added optional URL field

  ResourceLink({required this.name, required this.type, this.url});

  factory ResourceLink.fromJson(Map<String, dynamic> json) {
    return ResourceLink(
      name: json['name'],
      type: _parseResourceType(json['type']),
      url: json['url'],
    );
  }

  static ResourceType _parseResourceType(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return ResourceType.video;
      case 'article':
        return ResourceType.article;
      case 'documentation':
        return ResourceType.documentation;
      default:
        return ResourceType.course;
    }
  }
}
