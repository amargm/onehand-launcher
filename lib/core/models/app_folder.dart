/// A named collection of app package names shown as a dock folder.
class AppFolder {
  const AppFolder({
    required this.id,
    required this.name,
    required this.packageNames,
    this.iconKey = 'folder',
  });

  final String id;
  final String name;
  final List<String> packageNames;

  /// Key into [kFolderIcons] — persisted and used by the dock button.
  final String iconKey;

  AppFolder copyWith({
    String? id,
    String? name,
    List<String>? packageNames,
    String? iconKey,
  }) {
    return AppFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      packageNames: packageNames ?? this.packageNames,
      iconKey: iconKey ?? this.iconKey,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'packageNames': packageNames,
    'iconKey': iconKey,
  };

  factory AppFolder.fromJson(Map<String, dynamic> json) => AppFolder(
    id: json['id'] as String,
    name: json['name'] as String,
    packageNames: List<String>.from(json['packageNames'] as List),
    iconKey: (json['iconKey'] as String?) ?? 'folder',
  );
}
