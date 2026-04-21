enum DeviceEnum {
  Android(label: 'Android'),
  iOS(label: 'iOS'),
  PC(label: 'PC');

  final String label;

  const DeviceEnum({
    required this.label,
  });
}
