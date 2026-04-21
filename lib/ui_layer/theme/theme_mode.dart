enum MyThemeMode {

  system(type: 0, name: "Follow the system"),
  light(type: 1, name: "Light Mode"),
  dark(type: 2, name: "Dark Mode");

  const MyThemeMode({required this.type, required this.name});
  final int type;
  final String name;
}