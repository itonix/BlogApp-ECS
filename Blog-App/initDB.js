
 import pool from "./db.js";

// export async function initializeSchema() {
//   try {
//     // Create users table with status column
//     const createUsersTable = `
//       CREATE TABLE IF NOT EXISTS users (
//         id INT AUTO_INCREMENT PRIMARY KEY,
//         name VARCHAR(100) NOT NULL,
//         email VARCHAR(100) NOT NULL UNIQUE,
//         password VARCHAR(255) NOT NULL,
//         status ENUM('active', 'inactive') DEFAULT 'active',
//         created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
//       );
//     `;

//     // Create posts table with image_url column
// const createPostsTable = `
//   CREATE TABLE IF NOT EXISTS posts (
//     id INT AUTO_INCREMENT PRIMARY KEY,
//     user_id INT NOT NULL,
//     title VARCHAR(200) NOT NULL,
//     summary VARCHAR(500) NOT NULL,
//     content TEXT NOT NULL,
//     image_url VARCHAR(255),
//     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
//     FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
//   );
// `;


//     await pool.query(createUsersTable);
//     await pool.query(createPostsTable);

//     console.log("Database schema initialized (users + posts tables with image_url)");

//     // Insert test user if not exists
//     const [rows] = await pool.query(
//       "SELECT * FROM users WHERE email = ?",
//       ["tony@gmail.com"]
//     );

//     if (rows.length === 0) {
//       // Hash password before inserting
//       const bcrypt = await import('bcrypt');
//       const hashedPassword = await bcrypt.hash("1234", 10);

//       await pool.query(
//         "INSERT INTO users (name, email, password, status) VALUES (?, ?, ?, ?)",
//         ["tony", "tony@gmail.com", hashedPassword, "active"]
//       );

//       console.log("Test user 'tony' created");
//     } else {
//       console.log("Test user 'tony' already exists");
//     }

//   } catch (err) {
//     console.error("Error initializing schema:", err);
//     process.exit(1);
//   }
// }




//modified to initialize 3 users and 3 posts so that the App will have some data to display initially


export async function initializeSchema() {
  try {
    // Create tables
    const createUsersTable = `
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        status VARCHAR(20) NOT NULL DEFAULT 'active'
          CHECK (status IN ('active','inactive')),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      );
    `;

    const createPostsTable = `
      CREATE TABLE IF NOT EXISTS posts (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        title VARCHAR(200) NOT NULL,
        summary VARCHAR(500) NOT NULL,
        content TEXT NOT NULL,
        image_url VARCHAR(255),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        INDEX idx_posts_user_id (user_id)
      );
    `;

    await pool.query(createUsersTable);
    await pool.query(createPostsTable);

    console.log("Database schema initialized (users + posts)");

    // Insert 3 users if not exist
    const bcrypt = await import("bcrypt");
    const defaultUsers = [
      { name: "Tony", email: "tony@gmail.com" },
      { name: "Alice", email: "alice@gmail.com" },
      { name: "Bob", email: "bob@gmail.com" }
    ];

    const userIds = [];
    for (const user of defaultUsers) {
      const [rows] = await pool.query("SELECT id FROM users WHERE email = ?", [user.email]);
      if (rows.length === 0) {
        const hashedPassword = await bcrypt.hash("1234", 10);
        const [result] = await pool.query(
          "INSERT INTO users (name, email, password, status) VALUES (?, ?, ?, ?)",
          [user.name, user.email, hashedPassword, "active"]
        );
        userIds.push(result.insertId);
        console.log(`User '${user.name}' created`);
      } else {
        userIds.push(rows[0].id);
        console.log(`User '${user.name}' already exists`);
      }
    }

    // Insert 1 post per user if none exist
    const samplePosts = [
      {
        title: "Run JavaScript Everywhere with Node.js",
        summary: "Learn how to build your first Node.js app step by step.",
        content: "Node.js is an open-source and cross-platform JavaScript runtime environment. It is a popular tool for almost any kind of project!Node.js runs the V8 JavaScript engine, the core of Google Chrome, outside of the browser. This allows Node.js to be very performant.A Node.js app runs in a single process, without creating a new thread for every request. Node.js provides a set of asynchronous I/O primitives in its standard library that prevent JavaScript code from blocking. In addition, libraries in Node.js are generally written using non-blocking paradigms. Accordingly, blocking behavior is the exception rather than the norm in Node.js.",
        image_url: "https://www.edureka.co/blog/wp-content/uploads/2019/08/node-logo.png"
      },
      {
        title: "MySQL Workbench",
        summary: "MySQL Workbench is a graphical tool for working with MySQL servers and databases. ",
        content: "MySQL Workbench is developed and tested with MySQL Server 8.0. MySQL Workbench may connect to MySQL Server 8.4 and higher but some MySQL Workbench features may not function with those later server versions. MySQL Workbench is available on Windows, Linux, and macOS. MySQL Workbench provides data modeling, SQL development, and comprehensive administration tools for server configuration, user administration, backup, and much more.When started, MySQL Workbench opens to the home screen tab. Initially, the screen displays a welcome message and links to Browse Documentation >, Read the Blog >, and Discuss on the Forums >. In addition, the home screen provides quick access to MySQL connections, models, and the MySQL Workbench Migration Wizard. ",
        image_url: "https://dev.mysql.com/doc/workbench/en/images/wb-home-screen-new.png"
      },
      {
        title: "Automate Infrastructure on Any Cloud",
        summary: "Automate Infrastructure on Any Cloud with Terraform.",
        content: "Automate Infrastructure on Any Cloud with Terraform. Terraform is an open-source infrastructure as code software tool created by HashiCorp. It allows users to define and provision data center infrastructure using a high-level configuration language known as HashiCorp Configuration Language (HCL), or optionally JSON.Terraform supports a number of cloud providers such as AWS, Azure, Google Cloud, and many others. It enables users to manage both low-level components such as compute instances, storage, and networking, as well as high-level components such as DNS entries and SaaS features.Terraform is used to automate the provisioning and management of infrastructure in a consistent and repeatable manner, reducing the risk of human error and increasing efficiency.HashiCorp Terraform is an infrastructure as code tool that lets you define both cloud and on-prem resources in human-readable configuration files that you can version, reuse, and share. You can then use a consistent workflow to provision and manage all of your infrastructure throughout its lifecycle. Terraform can manage low-level components like compute, storage, and networking resources, as well as high-level components like DNS entries and SaaS features.",
        image_url: "https://web-unified-docs-hashicorp.vercel.app/api/assets/terraform/latest/img/docs/intro-terraform-workflow.png"
      }
    ];

    for (let i = 0; i < userIds.length; i++) {
      const [rows] = await pool.query("SELECT COUNT(*) as count FROM posts WHERE user_id = ?", [userIds[i]]);
      if (rows[0].count === 0) {
        await pool.query(
          "INSERT INTO posts (user_id, title, summary, content, image_url) VALUES (?, ?, ?, ?, ?)",
          [userIds[i], samplePosts[i].title, samplePosts[i].summary, samplePosts[i].content, samplePosts[i].image_url]
        );
        console.log(`Sample post inserted for user ${userIds[i]}`);
      }
    }

    console.log("3 users + 3 sample posts ready for carousel!");
  } catch (err) {
    console.error("Error initializing schema:", err.sqlMessage || err);
    process.exit(1);
  }
}
