enum BannerEventEnum{
  CLICK(label: 'click'),
  CLOSE(label: 'close'),
  SHOW(label: 'show');

  final String label;

  const BannerEventEnum({
    required this.label,
  });
}