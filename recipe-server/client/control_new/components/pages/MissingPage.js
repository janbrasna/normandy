import React from 'react';

export default function MissingPage() {
  return (
    <div className="page-404">
      <h1>404</h1>
      <p>Page not found.</p>
      <a onClick={() => window.history.back()}>Go back.</a>
    </div>
  );
}
