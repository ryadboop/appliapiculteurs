import confetti from 'canvas-confetti'

const forest = ['#14432b', '#2f6b46', '#7aa87f']
const honey = ['#e3a83b', '#edc272', '#c9911f']

export function celebrate() {
  const colors = [...forest, ...honey]
  const defaults = { spread: 70, ticks: 220, gravity: 0.9, scalar: 1, colors }

  confetti({ ...defaults, particleCount: 70, origin: { x: 0.5, y: 0.6 } })
  setTimeout(() => confetti({ ...defaults, particleCount: 45, angle: 60, origin: { x: 0.1, y: 0.7 } }), 140)
  setTimeout(() => confetti({ ...defaults, particleCount: 45, angle: 120, origin: { x: 0.9, y: 0.7 } }), 240)
}
