const express = require('express');
const os = require('os');
const app = express();

app.get('/', (req, res) => {
  const hostname = os.hostname();

  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>EC2 Load Balancer Demo</title>
      <style>
        body {
          font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
          background: #f4f6f8;
          color: #333;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          height: 100vh;
          margin: 0;
        }
        .card {
          background: white;
          padding: 2rem 3rem;
          border-radius: 12px;
          box-shadow: 0 8px 24px rgba(0,0,0,0.1);
          text-align: center;
        }
        h1 {
          color: #007acc;
          font-size: 2.5rem;
          margin-bottom: 0.5rem;
        }
        code {
          background: #e0e0e0;
          padding: 2px 6px;
          border-radius: 4px;
          font-family: monospace;
        }
      </style>
    </head>
    <body>
      <div class="card">
        <h1>🌐 Hello from ECS Cluster!</h1>
        <p>Served by container: <code>${hostname}</code></p>
      </div>
    </body>
    </html>
  `);
});

const PORT = process.env.PORT || 80;
app.listen(PORT, () => console.log(`App running on port ${PORT}`));
