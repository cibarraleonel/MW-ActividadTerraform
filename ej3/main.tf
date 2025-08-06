module "area_calc" {
  source = "./modules"
  height = 5
  width  = 3
}

output "message" {
  value = "El área de un ${module.area_calc.height} * ${module.area_calc.width} es ${module.area_calc.area}"
}
