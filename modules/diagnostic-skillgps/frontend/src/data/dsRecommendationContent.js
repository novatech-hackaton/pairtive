/**
 * Recommendation_Content — deterministic, predefined recommendation text per
 * topic. Used both as the display fallback when the Recommendation_Service is
 * unavailable, and as the grounding context sent to that service.
 *
 * Keyed by topic name (case-insensitive lookup via getRecommendationContent).
 * A topic with no specific entry gets a non-empty generic text naming it.
 */
const CONTENT_BY_TOPIC = {
  'Variables and Data Types': 'Review how each primitive and composite type stores values, and practice choosing the right type and converting between them.',
  'Operators and Expressions': 'Practice operator precedence and evaluating mixed expressions by hand before checking with code.',
  'Conditional Statements': 'Work through branching problems with if/else-if/else and switch, focusing on boolean conditions and edge cases.',
  'Loops': 'Trace for, while, and do-while loops step by step, paying attention to termination, break, and continue.',
  'Functions': 'Practice defining functions with parameters and return values, and reason about scope and parameter passing.',
  'Arrays and Strings': 'Drill indexing, iteration, and common string operations on small arrays and strings.',
  'Recursion': 'Trace base cases and the call stack with small examples, then build up to recursive problems like factorial and Fibonacci.',
  'Classes and Objects': 'Model real things as classes with state and behavior, and practice creating and using instances.',
  'Encapsulation': 'Practice hiding internal state behind accessors and reason about why controlled access matters.',
  'Inheritance': 'Build small class hierarchies and identify is-a relationships and reused behavior.',
  'Polymorphism': 'Practice overriding methods and calling them through a common interface to see dynamic dispatch.',
  'Sorting Algorithms': 'Trace a few sorts by hand on small arrays and compare their time complexity and stability.',
  'Searching Algorithms': 'Compare linear and binary search, and practice the conditions binary search requires.',
  'SQL Fundamentals': 'Write SELECT/INSERT/UPDATE/DELETE queries with filtering on a small sample schema.',
  'Joins and Subqueries': 'Practice inner and outer joins and rewrite some joins as subqueries to build intuition.',
};

export function getRecommendationContent(topicName) {
  if (typeof topicName === 'string') {
    const key = Object.keys(CONTENT_BY_TOPIC).find(
      (k) => k.toLowerCase() === topicName.trim().toLowerCase(),
    );
    if (key) return CONTENT_BY_TOPIC[key];
  }
  const name = topicName ? String(topicName) : 'this topic';
  return `Review the fundamentals of ${name} and practice with focused exercises to strengthen your understanding.`;
}

export default getRecommendationContent;
