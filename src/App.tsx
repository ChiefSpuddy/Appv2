import './styles/theme.css';
import { ThemeProvider } from './context/ThemeContext';
import Layout from './components/Layout';
import { useTheme } from './hooks/useTheme';

function App() {
  const { theme } = useTheme();

  return (
    <div className="app" data-theme={theme}>
      <ThemeProvider>
        <Layout>
          <div className="grid" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '1rem' }}>
            <div className="card">
              <h2>Welcome</h2>
              <p>This is your modernized app with theme support!</p>
              <button className="btn">Get Started</button>
            </div>
            
            <div className="card">
              <h2>Features</h2>
              <p>Explore the new theme system and modern UI components.</p>
              <button className="btn btn-secondary">Learn More</button>
            </div>
          </div>
        </Layout>
      </ThemeProvider>
    </div>
  );
}

export default App;
