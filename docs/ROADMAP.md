# Roadmap

Plan de evolución de Vitale por versiones. Las fechas son orientativas.

[← Volver al README](../README.md)

---

## v1.0 — Versión actual

Primera versión estable con el núcleo de la herramienta y arquitectura modular preparada para crecer.

### Conversión

- [x] Conversión HTML → Markdown con [mdream](https://github.com/harlan-zw/mdream)
- [x] Soporte nativo de MHTML/MHT
- [x] Detección de charset (UTF-8, ISO-8859-1, Windows-1252, Shift-JIS, GBK…)
- [x] Descarga con UTF-8 + BOM (acentos correctos en todos los visores)

### Extractores

- [x] Sistema de extractores auto-registrables
- [x] Detección automática del sitio de origen desde la URL del MHTML
- [x] Extractores específicos: Fanfiction.net, AO3, Webnovel, Royal Road, Wikipedia, Substack, Blogger
- [x] Fallback en cascada (extractor específico → genérico → HTML completo)
- [x] Pill visual del sitio detectado

### Interfaz

- [x] Panel de carga unificado con drag & drop
- [x] Pegado desde portapapeles con fallback
- [x] Asistente de URLs con instrucciones por plataforma
- [x] Modal para elegir nombre del archivo
- [x] Diseño oscuro responsive

### Arquitectura

- [x] Modularización del JS en 20 archivos por responsabilidad
- [x] Namespace global `window.Vitale` sin necesidad de bundler
- [x] Compatible con `file://` y GitHub Pages

---

## v1.1 — Próximas mejoras

Ampliación de extractores y mejoras de UX.

### Extractores nuevos

- [ ] Wattpad (`.part_content`, `[data-p-id]`)
- [ ] Medium (`.section-content`)
- [ ] Sufficient Velocity (`.messageContent`)
- [ ] Questionable Questing (`.messageContent`)
- [ ] Fanfiction.net (versión web completa, no solo móvil)
- [ ] Scribble Hub (`.chp_raw`)
- [ ] Novel Updates

### Funcionalidad

- [ ] Soporte para archivos EPUB
- [ ] Modo claro / oscuro conmutable
- [ ] Exportación directa a PDF
- [ ] Splitter de Markdown para RAG (dividir en chunks con overlap configurable)
- [ ] Interfaz de gestión de extractores desde la propia UI (ver, añadir, editar sin tocar código)

### Mejoras de UX

- [ ] Historial de conversiones recientes en localStorage
- [ ] Presets por sitio (por ejemplo, "solo contenido", "con metadatos", "con imágenes como links")
- [ ] Preview del Markdown con renderizado real (usando marked.js o similar)
- [ ] Botón "Compartir" en móvil (Web Share API con fallback a descarga)

---

## v1.2 — Internacionalización y accesibilidad

- [ ] Soporte multi-idioma (español, inglés, portugués)
- [ ] Mejoras de accesibilidad: navegación por teclado, ARIA, contraste WCAG AA
- [ ] Modo alto contraste
- [ ] Fuentes ajustables

---

## v2.0 — App Flutter

Port completo a Flutter para Android, iOS y Web con integración nativa.

### Arquitectura

- [ ] Clean Architecture con 3 capas (Presentation, Domain, Data)
- [ ] Gestión de estado con Riverpod
- [ ] Modularización por features
- [ ] Reutilización de los mismos extractores en Dart

### Funcionalidad nativa

- [ ] Integración con el menú "Compartir" del sistema operativo
- [ ] Selector de archivos nativo
- [ ] Guardado en carpetas del sistema (Downloads, Documents, iCloud)
- [ ] Notificaciones cuando termine una conversión larga

### Extras

- [ ] Historial local persistente
- [ ] Procesamiento por lotes (múltiples archivos)
- [ ] Sincronización opcional entre dispositivos (a través de servicios del usuario, no de terceros)
- [ ] Widget de acceso rápido en Android
- [ ] Atajos de teclado en versiones de escritorio

---

## Ideas sin fecha asignada

Sugerencias que pueden llegar en cualquier momento si hay demanda:

- [ ] Soporte para RSS feeds (convertir items a Markdown)
- [ ] API pública JavaScript (`window.Vitale.convert(html)`) para integrar en otras herramientas
- [ ] Extensión de navegador (Chrome/Firefox) que capture la página actual y la convierta
- [ ] CLI en Node.js para automatizar conversiones desde la terminal
- [ ] Integración con Obsidian, Notion, Logseq mediante plugins
- [ ] Modo "solo texto" que descarte todo excepto párrafos (sin headers ni listas)
- [ ] Filtros personalizados por el usuario (excluir selectores CSS específicos)

---

## Cómo proponer una mejora

Si tienes una idea que no está en el roadmap:

1. Abre un **issue** con la etiqueta `enhancement`.
2. Describe el caso de uso y por qué sería útil.
3. Si puedes, propone una implementación aproximada.

Las propuestas más votadas o con más sentido se incorporan al roadmap en la siguiente revisión.