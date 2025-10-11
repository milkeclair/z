import { Section } from './type';

export function useCurrentSection(defaultSection: Section) {
  let current: Section = defaultSection;

  const currentSection = () => current;

  const setCurrentSection = (newSection: Section) => {
    current = newSection;
  };

  return [currentSection, setCurrentSection] as const;
}
