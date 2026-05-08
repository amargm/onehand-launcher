/// A named collection of app package names shown as a dock folder.
class AppFolder {
  const AppFolder({
    required this.id,
    required this.name,
    required this.packageNames,
  });

  final String id;
  final String name;
  final List<String> packageNames;

  AppFolder copyWith({String? id, String? name, List<String>? packageNames}) {
    return AppFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      packageNames: packageNames ?? this.packageNames,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'packageNames': packageNames,
  };

  factory AppFolder.fromJson(Map<String, dynamic> json) => AppFolder(
    id: json['id'] as String,
    name: json['name'] as String,
    packageNames: List<String>.from(json['packageNames'] as List),
  );
}
