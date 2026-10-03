// Recommendation_Content: deterministic, predefined recommendation text per topic.
// Ported from the diagnostic-skillgps module (data/dsRecommendationContent.js).
// Keyed by topic name (case-insensitive, trimmed lookup). A topic with no specific
// entry gets a non-empty generic text naming it.

const AM_CONTENT_BY_TOPIC = Object.freeze({
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
});

const AM_CONTENT_BY_KEY = new Map(
  Object.entries(AM_CONTENT_BY_TOPIC).map(([name, text]) => [name.toLowerCase(), text]),
);

/** Recommendation text for a topic name; a generic, non-empty fallback when unknown. */
export function amGetRecommendationContent(topicName) {
  if (typeof topicName === 'string') {
    const hit = AM_CONTENT_BY_KEY.get(topicName.trim().toLowerCase());
    if (hit) return hit;
  }
  const name = topicName ? String(topicName) : 'this topic';
  return `Review the fundamentals of ${name} and practice with focused exercises to strengthen your understanding.`;
}

export default amGetRecommendationContent;
