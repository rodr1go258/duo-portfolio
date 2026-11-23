export interface Project {
  id: number;
  title: string;
  description: string;
  tech: string[];
  owner: string;
  year: number;
  link: string | null;
}

export interface Developer {
  id: string;
  name: string;
  role: string;
  focus: string[];
  bio: string;
  github: string;
  avatar: string;
}

export interface ContactPayload {
  name: string;
  email: string;
  message: string;
}
