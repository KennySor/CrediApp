import 'tdd_common.dart';

class ClienteTdd {
  ClienteTdd({
    required this.id,
    required this.nombre,
    required this.dni,
    required this.telefono,
    required this.direccion,
    this.eliminado = false,
  });

  final String id;
  String nombre;
  final String dni;
  String telefono;
  String direccion;
  bool eliminado;
}

abstract class ClienteRepository {
  Future<ClienteTdd?> buscarPorDni(String dni);
  Future<ClienteTdd?> buscarPorId(String id);
  Future<ClienteTdd> crear(ClienteTdd cliente);
  Future<void> actualizar(ClienteTdd cliente);
  Future<List<ClienteTdd>> listar();
  Future<List<ClienteTdd>> buscar(String criterio);
}

class ClienteService {
  ClienteService(this._repo);
  final ClienteRepository _repo;

  bool camposObligatoriosOk(String nombre, String dni, String telefono) =>
      nombre.trim().isNotEmpty && dni.trim().isNotEmpty && telefono.trim().isNotEmpty;

  Future<Resultado<ClienteTdd>> registrar({
    required String nombre,
    required String dni,
    required String telefono,
    required String direccion,
  }) async {
    if (!camposObligatoriosOk(nombre, dni, telefono)) {
      return const Resultado('CAMPOS_OBLIGATORIOS', 'Este campo es obligatorio');
    }
    try {
      final dup = await _repo.buscarPorDni(dni.trim());
      if (dup != null) {
        return const Resultado('CLIENTE_DUPLICADO', 'Cliente ya registrado');
      }
      final c = await _repo.crear(ClienteTdd(
        id: 'c${DateTime.now().millisecondsSinceEpoch}',
        nombre: nombre.trim(),
        dni: dni.trim(),
        telefono: telefono.trim(),
        direccion: direccion.trim(),
      ));
      return Resultado('OK', 'Cliente registrado', dato: c, ok: true);
    } on ConexionException {
      return const Resultado('ERROR_INTERNO', 'Error de base de datos al guardar el cliente');
    }
  }

  Future<Resultado<List<ClienteTdd>>> consultar({String? filtro}) async {
    try {
      final lista = filtro == null || filtro.trim().isEmpty
          ? await _repo.listar()
          : await _repo.buscar(filtro.trim());
      if (lista.isEmpty) {
        return Resultado(
          'SIN_DATOS',
          filtro == null ? 'Sin clientes registrados' : 'Sin coincidencias',
          dato: lista,
          ok: true,
        );
      }
      return Resultado('OK', 'Listado de clientes', dato: lista, ok: true);
    } on ConexionException {
      return const Resultado('TIMEOUT', 'Tiempo de espera excedido');
    }
  }

  Future<Resultado<ClienteTdd>> actualizar({
    required String id,
    required String telefono,
    required String direccion,
  }) async {
    if (telefono.trim().isEmpty) {
      return const Resultado('CAMPOS_OBLIGATORIOS', 'Este campo es obligatorio');
    }
    try {
      final c = await _repo.buscarPorId(id);
      if (c == null || c.eliminado) {
        return const Resultado('CLIENTE_ELIMINADO', 'Cliente eliminado por otro usuario');
      }
      c.telefono = telefono.trim();
      c.direccion = direccion.trim();
      await _repo.actualizar(c);
      return Resultado('OK', 'Cliente actualizado', dato: c, ok: true);
    } on ConexionException {
      return const Resultado('ERROR_INTERNO', 'Conflicto de versión simultáneo');
    }
  }

  Future<Resultado<ClienteTdd>> buscarUno(String criterio) async {
    if (criterio.trim().isEmpty || criterio.trim().length < 2) {
      return const Resultado('FORMATO_INVALIDO', 'Criterio de búsqueda con formato inválido');
    }
    try {
      final lista = await _repo.buscar(criterio.trim());
      if (lista.isEmpty) {
        return const Resultado('NO_ENCONTRADO', 'Cliente inexistente');
      }
      return Resultado('OK', 'Cliente encontrado', dato: lista.first, ok: true);
    } on ConexionException {
      return const Resultado('TIMEOUT', 'Tiempo de espera excedido');
    }
  }
}
