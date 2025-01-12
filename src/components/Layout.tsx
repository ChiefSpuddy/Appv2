import React from 'react';
import ThemeToggle from './ThemeToggle';

interface LayoutProps {
  children: React.ReactNode;
}

const Layout: React.FC<LayoutProps> = ({ children }) => {
  return (
    <div className="layout">
      <header className="flex" style={{
        padding: '1rem',
        borderBottom: '1px solid var(--border)',
        background: 'var(--surface)',
      }}>
        <div className="container flex" style={{ justifyContent: 'space-between', alignItems: 'center' }}>
          <h1 style={{ margin: 0 }}>Your App Name</h1>
          <ThemeToggle />
        </div>
      </header>
      
      <main className="container" style={{ padding: '2rem 1rem' }}>
        {children}
      </main>

      <footer style={{
        padding: '1rem',
        borderTop: '1px solid var(--border)',
        background: 'var(--surface)',
        textAlign: 'center',
      }}>
        <div className="container">
          <p style={{ margin: 0 }}>© 2024 Your App Name</p>
        </div>
      </footer>
    </div>
  );
};

export default Layout;
