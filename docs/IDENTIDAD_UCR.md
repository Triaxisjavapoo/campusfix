# Identidad visual UCR en CampusFix

CampusFix es un proyecto académico para la Universidad de Costa Rica, Sede del Sur. La interfaz utiliza los colores de la UCR y archivos gráficos institucionales originales. La incorporación de estos recursos no constituye una certificación ni un aval institucional del software.

## Fuentes oficiales consultadas

- [Línea gráfica de la Universidad de Costa Rica](https://www.ucr.ac.cr/sitios/linea-grafica.html).
- [Identidad visual de la Oficina de Comunicación Institucional](https://oci.ucr.ac.cr/identidad-visual.html).
- [Recursos gráficos de la Escuela de Psicología](https://psico.ucr.ac.cr/index.php/es/sitios-de-interes/recursos.html): enlace «Identidad visual UCR».
- [Paquete original de elementos de identidad](https://psico.ucr.ac.cr/images/recursos/elementosIdentidadUCR.zip).
- [Manual de identidad visual UCR, edición 2019](https://psico.ucr.ac.cr/images/recursos/2019_manual-identidad-visual-web.pdf).
- [Lineamientos de contenido e imagen para sitios web UCR](https://oci.ucr.ac.cr/sitios-web/manual-lineamientos-contenido-web/imprimir.html?empotrar=true&ruta=https%3A%2F%2Foci.ucr.ac.cr%2Fsitios-web%2Fmanual-lineamientos-contenido-web%2F.html).

Consulta: 21 de octubre de 2026. Los símbolos pertenecen a la Universidad de Costa Rica. OCI contempla su uso por estudiantes, docentes y colaboradores en actividades académicas y dirige su aplicación institucional. La identidad no debe interpretarse como una autorización para presentar este proyecto como un servicio oficial de la Universidad.

## Colores

| Color | HEX | Aplicación en la interfaz |
|---|---|---|
| Celeste UCR | `#00C0F3` | Cintillos, acentos y elementos de identidad |
| Azul UCR | `#005DA4` | Botones principales, navegación y títulos destacados |
| Blanco | `#FFFFFF` | Fondos, superficies y contraste |
| Amarillo de apoyo | `#FFE06A` | Detalles puntuales y acentos |

El azul se usa con texto blanco en los controles principales. El celeste se combina con texto oscuro para mantener legibilidad. Los estados de error, éxito y advertencia conservan colores funcionales diferenciados.

## Archivos incluidos

Los PNG se extrajeron directamente del paquete oficial. No se redibujaron, recortaron, recolorearon, deformaron ni regeneraron. Mantienen transparencia y proporciones originales; solo se cambió el nombre del archivo para su uso en la aplicación.

| Archivo local | Entrada en el ZIP original | Dimensiones | Tamaño |
|---|---|---|---|
| `assets/branding/ucr-firma-horizontal.png` | `elementos-identidad-ucr/video/png/firma-horizontal-una-linea-rgb.png` | 708 × 141 px | 19 201 bytes |
| `assets/branding/ucr-firma-horizontal-blanca.png` | `elementos-identidad-ucr/grises-neutrales/png/firma-horizontal-una-linea-blanco.png` | 708 × 141 px | 11 598 bytes |
| `assets/branding/ucr-firma-dos-lineas.png` | `elementos-identidad-ucr/video/png/firma-horizontal-dos-lineas-rgb.png` | 969 × 503 px | 72 678 bytes |

La interfaz utiliza la firma a color sobre blanco. La variante blanca se conserva para futuras superficies azules. La firma debe mantenerse completa, sin filtros, efectos ni texto superpuesto. El nombre CampusFix y la descripción de la aplicación se presentan como elementos separados de la firma institucional.

Para la firma de una línea, se recomienda un área de 252 × 50 px o mayor, con `BoxFit.contain`, sin distorsión. Los márgenes transparentes incluidos en el PNG forman parte del archivo original. La guía del cintillo establece una altura mínima de 50 px para esta firma y un cintillo de al menos 56 px. En composiciones con firma de dos líneas, se requiere un área mayor; la guía señala un cintillo mínimo de 108 px. La firma debe enlazar a la [página principal de la UCR](https://www.ucr.ac.cr/) cuando se utilice como parte del cintillo web.

Los recursos se empaquetan como assets locales de Flutter (`Image.asset`) para evitar dependencias de red, fuentes externas y paquetes adicionales de renderizado de imágenes.

## Verificación de integridad

SHA-256 de los archivos originales extraídos:

```text
ucr-firma-horizontal.png
2BCE6199D3A9D7E580417354DB570DD5AB23750BD67BE28B934ACD32A7C2CE43

ucr-firma-horizontal-blanca.png
373311722E2D895CDB10F19E27F2E83E49DB505309F8D96580840D04339B65EA

ucr-firma-dos-lineas.png
1BDBEE9505252FB18E0B2BAB1D5D36C957828183B595E3C77B072C61C8FB75B7
```
