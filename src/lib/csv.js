function escapeCell(value) {
  return `"${String(value ?? '').replace(/"/g, '""')}"`
}

/** Construit une chaîne CSV (séparateur ";", adapté à Excel en français). */
export function toCsvString(headers, rows) {
  const lignes = [headers, ...rows]
  return lignes.map((ligne) => ligne.map(escapeCell).join(';')).join('\r\n')
}

/** Déclenche le téléchargement d'un CSV dans le navigateur. */
export function downloadCsv(filename, headers, rows) {
  const csv = toCsvString(headers, rows)
  // BOM UTF-8 : sans ça, Excel affiche mal les accents.
  const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  a.click()
  URL.revokeObjectURL(url)
}

export function dateStamp() {
  return new Date().toISOString().slice(0, 10)
}
