
import pool from "./db.js";

import dotenv from "dotenv";
dotenv.config();

import bcrypt from "bcrypt";
import express from "express"; // now process.env.DB_* are defined
import { hostname, uptime, totalmem } from 'os';
// rest of your imports
import path from 'node:path';
import session from 'express-session';
import { initializeSchema } from "./initDB.js";
import { fileURLToPath } from 'node:url';
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { LambdaClient, InvokeCommand } from "@aws-sdk/client-lambda";
const lambda = new LambdaClient({ region: process.env.AWS_REGION });
import multer from "multer";
import crypto from "crypto";
// in app.js or server.js

const app = express();
const port = 3001;
app.set("view engine", "ejs");
app.set("views", "./views");
app.use(express.static("public"));
app.use(express.urlencoded({ extended: true }));

// Configure multer for file upload (memory storage)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 1 * 1024 * 1024 }, // 1 MB
}).single("image");

// Initialize DB schema before starting server
initializeSchema().then(() => {
  console.log("Database schema ready");
  app.listen(port, () => console.log(`Server running on port ${port}`));
}).catch(err => {
  console.error("Failed to initialize schema:", err);
  process.exit(1);
});


const _dirname = path.dirname(fileURLToPath(import.meta.url));

console.log(_dirname);
app.use('/tinymce', express.static(path.join(_dirname, 'node_modules', 'tinymce')));
// ✅ Enable parsing of URL-encoded form data
app.use(express.static(path.join(_dirname, 'public_html')));


function ensureAuthenticated(req, res, next) {
  if (req.session && req.session.isAuthenticated) {
    return next(); // ✅ allow access
  }
  console.log("unauthenticated Access");
  res.status(403).send('Forbidden - Please login first');
}


//app.use(customMiddleware);
// setup the logger
// app.use(morgan('combined', { stream: accessLogStream }))
// Optional: for JSON if you're using raw JSON in Postman
// app.use(express.json());

app.use(session({
  secret: 'wereoko4920/5j', // change to something strong
  resave: false,
  saveUninitialized: false
}));
app.use((req, res, next) => {
  res.locals.isAuthenticated = req.session.isAuthenticated || false;
  next();
});

/////////////////////////////////// FOR TESTING API ////////////////////////////


app.get('/system/health', (req, res) => {
  const uptimeSeconds = uptime();
  const uptimeFormatted = `${Math.floor(uptimeSeconds / 3600)}h ${Math.floor((uptimeSeconds % 3600) / 60)}m`;
  const totalMemoryGB = (totalmem() / (1024 ** 3)).toFixed(2);

  res.status(200).json({
    hostname: hostname(),
    uptime: uptimeFormatted,
    totalMemory: `${totalMemoryGB} GB`
  });
});
/////////////////////////////////////////////////////////////////////////////////
app.get('/', (req, res) => {
  console.log("Rendering home page");
  res.render('index');
})

app.get("/read-blogs", async (req, res) => {
  const page = parseInt(req.query.page) || 1; // default page 1
  const limit = 3;
  const offset = (page - 1) * limit;

  try {
    // Fetch posts for current page
    const [posts] = await pool.query(`
      SELECT p.id, p.title, p.summary, p.image_url, u.name AS author, p.created_at
      FROM posts p
      JOIN users u ON p.user_id = u.id
      ORDER BY p.created_at DESC
      LIMIT ? OFFSET ?
    `, [limit, offset]);

    // Count total posts to know if "Next" should be shown
    const [countResult] = await pool.query(`SELECT COUNT(*) as total FROM posts`);
    const totalPosts = countResult[0].total;
    const totalPages = Math.ceil(totalPosts / limit);

    res.render("read-blogs", { posts, page, totalPages });
  } catch (err) {
    console.error(err);
    res.status(500).send("Failed to load posts");
  }
});

// Blog detail route for single page view of a blog post
app.get("/blog/:id", async (req, res) => {
  const blogId = req.params.id;
  try {
    const [rows] = await pool.query(`
      SELECT p.*, u.name AS author
      FROM posts p
      JOIN users u ON p.user_id = u.id
      WHERE p.id = ?
    `, [blogId]);

    if(rows.length === 0) return res.status(404).send("Blog not found");

    res.render("blog-detail", { post: rows[0] });
  } catch(err) {
    console.error(err);
    res.status(500).send("Failed to load blog");
  }
});



app.get('/about', (req, res) => {
  console.log("Rendering about page");
  res.render('about');
});

app.get('/contact', (req, res) => {
  console.log("Rendering contact page");
  res.render('contact');  
});

app.get('/blogs', ensureAuthenticated, (req, res) => {
  res.render('blogs', { userName: req.session.userName });
});

app.get('/register', (req, res) => {
  res.render('register'); // render register.ejs or your registration template
});

app.get('/signin', (req, res) => {
  res.render('signin'); // render signin.ejs or your signin template
} 
);




///////////FOR TESTIONG PURPOSE ONLY INFO PAGE ////////////////////////////
// app.get('/about/info', (req, res) => {
//   const uptimeSeconds = uptime();
//   const uptimeFormatted = `${Math.floor(uptimeSeconds / 3600)}h ${Math.floor((uptimeSeconds % 3600) / 60)}m`;

//   const totalMemoryGB = (totalmem() / (1024 ** 3)).toFixed(2); // Convert bytes to GB

//   res.render('about/info', {
//     hostname: hostname(),
//     uptime: uptimeFormatted,
//     totalmemory: `${totalMemoryGB} GB`
//   });
// });

/////////////////////////////////// FOR TESTING API ////////////////////////////

// app.get('/system/info', (req, res) => {
//   const uptimeSeconds = uptime();
//   const uptimeFormatted = `${Math.floor(uptimeSeconds / 3600)}h ${Math.floor((uptimeSeconds % 3600) / 60)}m`;
//   const totalMemoryGB = (totalmem() / (1024 ** 3)).toFixed(2);

//   res.status(200).json({
//     hostname: hostname(),
//     uptime: uptimeFormatted,
//     totalMemoryGB
//   });
// });








/////////////////////////////////////////////// TESTING PURPOSE ONLY INFO PAGE ////////////////////////////

// Registration route with password hashing and DB insertion for new user if duplicate entry exits throw error ////////////////////////////
app.post("/register", async (req, res) => {
  console.log(req.body);
  const { name, email, password, confirm_password } = req.body;

  if (password !== confirm_password) {
    return res.status(400).send("<p>Passwords do not match!</p>");
  }

  try {
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert user into database
    const [result] = await pool.query(
      "INSERT INTO users (name, email, password) VALUES (?, ?, ?)",
      [name, email, hashedPassword]
    );

    console.log("User registered with ID:", result.insertId);
     //Prepare payload for Lambda
    const payload = JSON.stringify({
      customerName: name,
      customerEmail: email
    });
    // const input = {
    //   FunctionName: "myWelcomemailfunction",
    //   InvocationType: "Event",
    //   Payload: Buffer.from(payload),
    // };
    const input = {
      FunctionName: "arn:aws:lambda:eu-west-2:895581202168:function:welcomefunction", // replace with your function ARN
      InvocationType: "Event",
      Payload: Buffer.from(payload),
    };
    const command = new InvokeCommand(input);
    const response = await lambda.send(command);
    console.log("Lambda invoked:", response);
     // Send success response to user
    //res
     // .status(200)
     // .send(`<p>Registration successful! Your user ID is ${result.insertId}</p>`);
      res.redirect('/signin');
  } catch (err) {
    console.error("DB error during registration:", err);

    if (err.code === "ER_DUP_ENTRY") {
      return res.status(400).send("<p>Email already exists!</p>");
    }

    res
    .status(500)
    .send(`<p>Registration failed due to a server error: ${err.message || "Unknown error"}</p>`);
  }
});


// Create post route with session management and DB insertion////////////////////////////

app.post('/create-post', (req, res) => {
  upload(req, res, async (err) => {
    if (err) {
      console.error("Multer error:", err);
      return res.status(400).send("File upload error: " + err.message);
    }

    try {
      if (!req.session || !req.session.isAuthenticated) {
        return res.status(403).send("Forbidden - Please login first");
      }
      const username = req.session.userName;
      const userId = req.session.userId;
      console.log("Creating post for user ID:", userId);
      const { title, summary, content } = req.body;

      if (!title || !content || !summary) {
        return res.status(400).send("Title ,content and summary  are required");
      }

      let imageUrl = null;

      if (req.file) {
        const fileName = `uploads/${userId}-${username}/${Date.now()}-${req.file.originalname}`;
        const bucketName = process.env.S3_BUCKET_NAME;

        const command = new PutObjectCommand({
          Bucket: bucketName,
          Key: fileName,
          Body: req.file.buffer,
          ContentType: req.file.mimetype
        });

        await s3Client.send(command);

        imageUrl = `https://${bucketName}.s3.${process.env.AWS_REGION}.amazonaws.com/${fileName}`;
      }

      await pool.query(
        "INSERT INTO posts (user_id, title, summary, content, image_url) VALUES (?, ?, ?, ?, ?)",
        [userId, title, summary, content, imageUrl]
      );
      console.log("Post created successfully");
      res.redirect("/blogs");
    } catch (error) {
      console.error("Error creating post:", error);
      res.status(500).send("Server error - could not create post");
    }
  });
});






//signin route with session management checking databases for validity////////////////////////////

app.post('/signin', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.render('invalidsignin', { error: 'Email and password are required' });
  }

  try {
    const [rows] = await pool.query(
      "SELECT * FROM users WHERE email = ? AND status = 'active'",
      [email]
    );

    if (rows.length === 0) {
      return res.render('invalidsignin', { error: 'Invalid email or password' });
    }

    const user = rows[0];

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.render('invalidsignin', { error: 'Invalid email or password' });
    }

    // Store user info in session
    req.session.isAuthenticated = true;
    req.session.userId = user.id;
    req.session.userName = user.name;
    console.log(req.session.userName);
    
    console.log("User authenticated successfully:", user.email);
    res.redirect('/blogs');

  } catch (err) {
    console.error("Signin DB error:", err);
    res.status(500).render('invalidsignin', { error: 'Server error. Try again later.' });
  }
});



//////////////////////////////////////////////////////////////////////logout route to destroy session
app.get('/logout', (req, res) => {
  req.session.destroy(err => {
    if (err) {
      console.error("Logout error:", err);
      return res.status(500).send("Error logging out");
    }
    res.redirect('/'); // back to homepage after logout
  });
});






const s3Client = new S3Client({
  region: process.env.S3_BUCKET_REGION, // bucket's region

});

