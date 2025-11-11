import { S3Client, GetObjectCommand } from "@aws-sdk/client-s3";
import { SESClient, SendEmailCommand } from "@aws-sdk/client-ses";

const s3 = new S3Client({ region: "eu-west-2" });
const ses = new SESClient({ region: "eu-west-2" });

export const handler = async (event) => {
  const { customerName, customerEmail } = event;
  const subject = `Welcome ${customerName} from Blog-APP`;
  const response = await s3.send(new GetObjectCommand({
    
    Bucket: "my-wemail-template",
    Key: "welcomemail.html"
  }));
  
  const body = await streamToString(response.Body);
  const html = body.replace("{{name}}", customerName);

  await ses.send(new SendEmailCommand({
    Source: "noreply@just4study.click",
    Destination: { ToAddresses: [customerEmail] },
    Message: {
      Subject: { Data: subject },
      Body: { Html: { Data: html } }
    }
  }));

  return { statusCode: 200, body: "Welcome email sent successfully" };
};

// Helper to convert stream to string
const streamToString = (stream) =>
  new Promise((resolve, reject) => {
    const chunks = [];
    stream.on("data", (chunk) => chunks.push(chunk));
    stream.on("error", reject);
    stream.on("end", () => resolve(Buffer.concat(chunks).toString("utf-8")));
  });
