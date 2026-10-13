# Contribuir a Vitale

Gracias por querer aportar a Vitale. Este documento explica cómo colaborar de forma ordenada.

[← Volver al README](../README.md)

---

## Antes de empezar

Vitale sigue una filosofía clara que conviene respetar:

- **Vanilla hasta el final** — sin frameworks, sin bundlers, sin npm. Todo el código debe poder ejecutarse abriendo `index.html`.
- **Sin dependencias externas** — la única excepción es el motor mdream, que se carga desde CDN.
- **Un archivo = una responsabilidad** — cada archivo JS debe hacer una cosa y hacerla bien.
- **Funciona offline** — nada debe requerir conexión después de la primera carga.

Si tu propuesta rompe alguno de estos principios, probablemente no sea aceptada.

---

## Cómo contribuir

### 1. Abre un issue primero

Antes de escribir código, describe lo que quieres hacer en un issue:

- **Bug** → usa la etiqueta `bug`.
- **Mejora** → usa la etiqueta `enhancement`.
- **Extractor nuevo** → usa la etiqueta `extractor`.

Esto permite discutir la aproximación antes de invertir tiempo en código.

### 2. Haz fork del repositorio

```bash
git clone https://github.com/tu-usuario/vitale.git
cd vitale
```

### 3. Crea una rama descriptiva

```bash
git checkout -b feature/nombre-corto
# o
git checkout -b fix/nombre-del-bug
```

### 4. Programa tu cambio

- **Mantén el estilo** del código existente.
- **Documenta** las funciones nuevas con comentarios claros.
- **Prueba** en al menos dos navegadores (Chrome y Firefox).
- **No rompas** funcionalidad existente.

### 5. Envía un pull request

- Explica qué cambia y por qué.
- Referencia el issue relacionado si lo hay.
- Adjunta capturas si es un cambio visual.

---

## Añadir un extractor nuevo

Es la contribución más común y la más sencilla. Consulta [docs/SITIOS.md](SITIOS.md#cómo-añadir-soporte-para-un-sitio-nuevo) para la guía completa.

Resumen:

1. Crea `prototipe/js/extractors/mi-sitio.js`.
2. Regístralo con `Vitale.extractors.register()`.
3. Añade una línea al `index.html`.
4. Prueba con un MHTML real del sitio.

### Checklist de un extractor

- [ ] El dominio está bien escrito en `domains`.
- [ ] El `label` es legible y en una sola palabra o nombre corto.
- [ ] Los selectores devuelven el contenido correcto (probado con DevTools).
- [ ] El extractor no captura menús, cabeceras ni publicidad.
- [ ] Funciona con un MHTML guardado desde Chrome de escritorio.
- [ ] Funciona con un MHTML guardado desde Chrome de Android (si aplica).

---

## Reportar un bug

Al abrir un issue con la etiqueta `bug`, incluye:

- **Navegador y versión** — Chrome 120, Firefox 121, Safari 17.
- **Sistema operativo** — Windows 11, macOS 14, Android 14, iOS 17.
- **Tipo de archivo** — `.html`, `.mhtml`, pegado desde portapapeles.
- **URL de origen** — si aplica, para saber qué extractor se usó.
- **Pasos para reproducir** — numerados, concretos.
- **Comportamiento esperado vs. real.**
- **Capturas** si es un problema visual.
- **Fragmento del MHTML** si es un problema de conversión (asegúrate de que no contiene datos personales).

### Bugs conocidos por plataforma

- **Android con WebView**: el selector de archivos puede no abrirse. Solución: abrir `index.html` en Chrome o Firefox, no en WebView integrado.
- **iOS Safari**: el esquema `view-source:` no funciona. Solución: usar "Guardar en Archivos" desde Compartir.
- **CORS en `file://`**: el `import()` a jsDelivr puede fallar en algunos navegadores si abres el HTML con doble clic. Solución: usar un servidor local (`python -m http.server`).

---

## Estilo de código

### JavaScript

- **Vanilla estricto** — sin transpilers, sin polyfills.
- **Sin punto y coma obligatorio** — pero sé consistente dentro de un archivo.
- **Comillas simples** en strings.
- **`const` y `let`** — nunca `var`.
- **Funciones puras siempre que se pueda.**
- **Comentarios en español** para bloques grandes, en inglés para detalles técnicos si es más natural.

### CSS

- **Variables CSS** para todo lo que se repita.
- **Sin preprocesadores** — CSS puro.
- **Sin frameworks** — nada de Tailwind, Bootstrap, etc.
- **Organizado por secciones** — respeta el índice del archivo.

### HTML

- **Semántico** siempre que se pueda.
- **Accesibilidad primero** — usa `aria-*` cuando corresponda.
- **Sin frameworks** — nada de React, Vue, etc.

---

## Pruebas manuales

No hay tests automatizados (todavía). Antes de enviar un PR, verifica manualmente:

- [ ] Abre `index.html` y comprueba que la app arranca sin errores en consola.
- [ ] Carga un MHTML de prueba y verifica que la conversión funciona.
- [ ] Prueba en móvil (o emulador de DevTools).
- [ ] Comprueba que el CSS no se rompe en móvil y escritorio.
- [ ] Verifica que no hay `console.error` en la consola.

### MHTML de prueba

Si necesitas MHTML de prueba, puedes generarlos tú mismo:

1. Abre un artículo en Chrome.
2. Pulsa `Ctrl+S`.
3. Elige **"Página web, un solo archivo"**.
4. Guarda el `.mhtml` en `prototipe/tests/fixtures/`.

No subas MHTML con contenido sensible al repositorio.

---

## Ideas de contribución

Sugerencias para quien quiera empezar:

- Añadir un extractor para un sitio que uses mucho.
- Mejorar la accesibilidad (ARIA, navegación por teclado).
- Traducir la interfaz a otro idioma.
- Escribir documentación o ejemplos.
- Reportar bugs con reproducción detallada.

---

## Código de conducta

Sé respetuoso. Los mantenedores se reservan el derecho de cerrar issues o PRs que no sigan este principio.

---

## Licencia de las contribuciones

Al enviar un PR aceptas que tu código se publique bajo la misma [Licencia MIT](../LICENSE) que el resto del proyecto.