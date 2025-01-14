import { useTheme } from '../hooks/useTheme';

export default function Menu() {
  const { theme, toggleTheme } = useTheme();

  return (
    <nav className="menu">
      <div className="menu-content">
        <ul>
          <li><a href="/">Home</a></li>
          <li><a href="/search">Search</a></li>
          <li><a href="/collection">Collection</a></li>
          <li><a href="/profile">Profile</a></li>
        </ul>
        <button 
          onClick={toggleTheme} 
          className="theme-toggle"
          title={`Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`}
        >
          {theme === 'dark' ? '☀️' : '🌙'}
        </button>
      </div>
    </nav>
  );
}
