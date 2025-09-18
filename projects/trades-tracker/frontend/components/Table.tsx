import { ReactNode } from 'react'
export function T({ children }: { children: ReactNode }) { return <table className="table">{children}</table> }
export function TH({ children }: { children: ReactNode }) { return <th>{children}</th> }
export function TR({ children }: { children: ReactNode }) { return <tr>{children}</tr> }
export function TD({ children }: { children: ReactNode }) { return <td>{children}</td> }
