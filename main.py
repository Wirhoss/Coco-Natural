import cx_Oracle

def conectar():
  try:
    conexion = cx_Oracle.connect(
      user="coco_natural",
      password="7zMFrmrX$cy5s7%8",
      dsn="localhost:1521/XEPDB1"
    )
    print("¡Conexión exitosa!")
    return conexion
  except cx_Oracle.Error as error:
    print(f"Error: {error}")
    return None

#EJEMPLO DE DAO PARA USAR EN EL FUTURO NOTA: Esto no lo he probado
# class ProductoDAO:
#   def __init__(self, conexion):
#     self.conexion = conexion
  
#   def crear(self, producto):
#     cursor = self.conexion.cursor()
#     cursor.callproc("pkg_productos.insertar", [
#       producto.nombre, 
#       producto.descripcion,
#       producto.precio
#     ])
#     self.conexion.commit()

#TODO: Esto hay que hacerlo bien, por ahora solo es un ejemplo
if __name__ == "__main__":
  conexion = conectar()
  if conexion:
    cursor = conexion.cursor()
    cursor.callproc("pkg_productos.obtener_productos")
    for fila in cursor:
      print(fila)
    conexion.close()