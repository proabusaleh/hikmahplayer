enum HikmahMediaType {
  video(0),
  audio(1),
  mixed(2);

  const HikmahMediaType(this.value);

  final int value;

  static HikmahMediaType fromValue(int value) =>
      HikmahMediaType.values.firstWhere(
        (t) => t.value == value,
        orElse: () => HikmahMediaType.video,
      );
}
