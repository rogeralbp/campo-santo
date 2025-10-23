# Campo Santo – Gestión descentralizada de cementerios

Este proyecto implementa un contrato inteligente escrito en Cairo 1 para Starknet. El contrato
modela la administración de un cementerio en el que las filas de tumbas se registran de manera
estrictamente alfabética y cada espacio tiene vigencia perpetua. La información sensible de las
familias usuarias no se almacena en texto plano, sino como compromisos criptográficos calculados
con el hash de Pedersen, lo que permite validar la titularidad sin revelar datos personales.

## Características principales

- **Gobernanza administrada:** únicamente la cuenta administradora puede registrar nuevas filas
  o espacios.
- **Filas ordenadas alfabéticamente:** el contrato impide registrar una fila con un identificador
  inferior al último registrado para mantener el orden lexicográfico (A, B, C, ...).
- **Espacios perpetuos:** cada registro de tumba queda marcado como perpetuo y conserva marcas de
  tiempo de creación y última actualización.
- **Compromisos criptográficos:** los datos sensibles (p. ej. nombre, acta, ubicación exacta)
  deben convertirse off-chain en un hash (por ejemplo Poseidon o Blake2) y después mezclarse con
  un secreto mediante `pedersen_hash`. El resultado es el compromiso que se almacena on-chain.
- **Validación sin revelar datos:** cualquier parte puede verificar si un compromiso propuesto
  coincide con el registrado usando la función `verify_plot_commitment`.

## Estructura

```
Scarb.toml      # Configuración del paquete Cairo / Starknet
src/lib.cairo   # Implementación del contrato `campo_santo`
ui/             # Prototipo de interfaz para presentar a clientes
```

## Probar el prototipo de interfaz

El directorio `ui/` contiene una maqueta inicial diseñada para reuniones con clientes. Para
explorarla localmente:

```bash
cd ui
python -m http.server 5173
# Abrir http://localhost:5173 en el navegador
```

La interfaz simula el mapa de filas alfabéticas, destaca los pilares de seguridad y describe el
roadmap del MVP para facilitar conversaciones de descubrimiento.

## Requisitos previos

1. Instalar [Scarb](https://docs.swmansion.com/scarb/) y `starknet-compile` compatibles con la
   edición `2023_11`.
2. Activar una cuenta de desarrollo en Starknet (local o testnet) si se desea desplegar.

## Comandos útiles

```bash
# Compilar el contrato
scarb build

# Ejecutar pruebas (si se agregan en `tests/`)
scarb test

# Formatear el código
scarb fmt
```

## Flujo recomendado para registrar tumbas

1. **Registrar filas:** el administrador llama a `register_row` con el valor ASCII de la letra (A =
   65, B = 66, etc.). El contrato garantiza que la secuencia es estrictamente creciente.
2. **Preparar la información sensible:** fuera de la cadena se generan dos valores:
   - `hashed_payload`: hash del JSON o estructura con los datos privados del titular.
   - `secret`: un número aleatorio conocido solo por la administración y la familia.
3. **Calcular el compromiso:** usar la vista `compute_commitment` o calcular localmente
   `pedersen_hash(hashed_payload, secret)`.
4. **Registrar el espacio:** llamar a `register_plot` con la fila, número de tumba y los dos
   compromisos (por ejemplo, uno para la persona titular y otro para metadatos adicionales).
5. **Verificar en el futuro:** proporcionar nuevamente `hashed_payload` y `secret` a la función
   `verify_plot_commitment` para demostrar la titularidad sin revelar información sensible.

Con este flujo se consigue una administración transparente y auditable, a la vez que se protege la
privacidad de los datos perpetuos asociados a cada espacio del cementerio.
