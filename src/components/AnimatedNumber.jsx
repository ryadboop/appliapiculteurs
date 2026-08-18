import { useEffect, useRef, useState } from 'react'
import { animate } from 'framer-motion'

export default function AnimatedNumber({ value, formatter = (n) => Math.round(n).toLocaleString('fr-FR') }) {
  const [display, setDisplay] = useState(0)
  const previous = useRef(0)

  useEffect(() => {
    const controls = animate(previous.current, value, {
      duration: 0.8,
      ease: 'easeOut',
      onUpdate: (v) => setDisplay(v),
    })
    previous.current = value
    return () => controls.stop()
  }, [value])

  return <>{formatter(display)}</>
}
