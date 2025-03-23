String getNutrientUnit(String label) {
  const microgram = ["비타민 A", "비타민 D", "비타민 K", "비타민 B12", "엽산"];
  const milligram = [
    "비타민 B1", "비타민 B2", "비타민 B3", "비타민 B6", "비타민 C", "비타민 E",
    "철분", "마그네슘", "아연", "인", "칼슘", "나트륨", "칼륨"
  ];
  const gram = ["탄수화물", "단백질", "지방", "식이섬유", "오메가-3"];

  if (microgram.contains(label)) return "μg";
  if (milligram.contains(label)) return "mg";
  return "g";
}
