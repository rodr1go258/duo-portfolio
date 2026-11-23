export interface Developer {
  id: string;
  name: string;
  role: string;
  focus: string[];
  bio: string;
  github: string;
  avatar: string;
}

/** The two-person team behind the MVP. */
export const DEVELOPERS: Developer[] = [
  {
    id: 'ana',
    name: 'Ana Torres',
    role: 'Frontend & Product',
    focus: ['React', 'TypeScript', 'Diseño de producto'],
    bio: 'Convierte ideas complejas en interfaces claras, accesibles y rápidas.',
    github: 'https://github.com/',
    avatar: 'AT'
  },
  {
    id: 'luis',
    name: 'Luis Ramírez',
    role: 'Backend & Platform',
    focus: ['Node.js', 'PostgreSQL', 'DevOps'],
    bio: 'Construye APIs resilientes y automatiza despliegues de punta a punta.',
    github: 'https://github.com/',
    avatar: 'LR'
  }
];
