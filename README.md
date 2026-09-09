# DSAN 6000 Homework 1: Linux Basics on EC2

**Due Friday, September 11, 5:59pm EDT**

> [!WARNING]
> If you have cloned the repository **template** from the `https://github.com/jpowerj/dsan6000-hw01-linux-basics` URL, you are **not starting the assignment correctly!** That is, if the command you used to clone the repo onto EC2 looks like:
> 
> `git clone https://github.com/jpowerj/dsan6000-hw01-linux-basics`
> 
> This will **not work** for assignments in this course, since you **will not be able to push your changes** back to this repository! (Notice how the above code purposefully has *no copy button!*) Instead, you need to create your **own version of the template**, as described in Step 0.

### Creating Your Own Repo From the Template

Click the **green "Use this template" button** in the upper-right corner of the template repo on GitHub, then choose the "Create a new repository" option. On the next page, you will be able to create a **new repository** in **your own GitHub account**, which you should call **`dsan6000-hw01-linux-basics`** (the same name as the template).

Once this **derived** repository has been set up on **your GitHub account**, you should first **submit the URL for your newly-created repository on Canvas, immediately after it has been created**: this is what will allow us to see your progress and check any issues between distribution and submission.

Then, once you have submitted the URL on Canvas, **clone *this* newly-created repository (*not* the template owned by `jpowerj`) to your EC2 instance to begin working!** In other words, the command you run on EC2 should look as follows (with your GitHub username in place of `YOUR_GH_USERNAME`):

```bash
git clone https://github.com/YOUR_GH_USERNAME/dsan6000-hw01-linux-basics
```

## HW1 Task: Downloading and (Basic) Processing of OLTP Data

In class this week you learned about **Online Transaction Processing (OLTP)** as the "entry point" for how we end up with "big" data: records of events like user interactions with a website (called "transactions" just for historical reasons, since they are not restricted to economic transactions!) **stream into the rows of an OLTP database** at a rapid rate, such that these databases are optimized solely for **ultra-frequent *writes***.

This first OLTP "stage" of the big data pipeline thus contrasts with the **Online Analytics Processing (OLAP)** stage, where the data from an OLTP database is extracted in batches and then typically **re-structured** into a columnar format like Apache Arrow. Whereas the row-based format of OLTP databases is what allows for rapid insertions, the columnar format of OLAP databases means that these are instead optimized for the kinds of **mathematical** (statistical, linear-algebraic) operations that we may need to perform to:

* Identify statistical trends (via operations like means and standard deviations), and
* Train machine learning models (via operations like convolution in a CNN)

We will gain lots of experience with these fancier "downstream" tasks later on in the course! For now, the goal of this assignment is for you to gain hands-on experience with the OLTP stage, so you have a concrete example (in this case, user events on Wikipedia) of what the "raw" upstream data looks like before it is extracted, cleaned, and employed for these downstream statistical/ML tasks.

### The Data: Wikimedia's `recentchange` Event Stream

The [Wikimedia Foundation](https://www.wikimedia.org/) is the parent organization that operates the Wikipedia website. In this role, therefore, it maintains a bunch of **servers** which are set up to handle:

* Simple `GET` requests from web browsers asking to **view** Wikipedia articles, but also
* The fancier `POST` requests that are involved when users **add new pages**, **edit or delete existing pages**, when administrators **approve or deny these edits/deletions**, and so on.

The data source for this homework is a **stream of events** covering this second category (events more complex than simple page views), providing your first hands-on experience with OLTP-style data!

Before getting started, Wikimedia has a web-based viewer for this event stream that you should check out [here](https://stream.wikimedia.org/v2/ui/#/?streams=recentchange)! It looks as follows:

![*Data for the first two events, out of the 53 Wikipedia `recentchange` events that streamed into the web interface in less than 1 second!*](recentchange.jpeg)

However, once you click the green "Stream" button in the upper-right of the interface, you will likely only see events for a second or two before recieving a popup message about reaching the event limit. In the above screenshot, for example, rows were entering the event DB at a rate of 65.4 events per second (so that the 100-event limit was reached after about 1.5 seconds).

This is an example of the frantic speed of events that an OLTP database needs to handle, and this example was chosen specifically to be *slow enough* so that you could at least see them streaming in for ~one second: think of how quickly you'd reach the 100-event limit in a stream of Wikipedia page *views*, for example.

This example hopefully helps drive home the points from Week 1, that (a) OLTP databases need to be optimized for rapid **writes**, and that (b) it's not feasible to use a library like Pandas or tidyverse to manage this data in its current form (at least, not feasible *yet*, with the data science tools you've learned prior to this course... 😉)

So, with that background in place, in this homework you will use the Linux shell to:

* **Download** this data from an S3 bucket,
* **Organize it** to make it a bit more amenable to (eventual) statistical analysis or ML model training, and
* Compute some basic **summary statistics** about the range of hourly event rates

Since this homework is intended solely to get you comfortable with starting a data-processing workflow on your EC2 instances, you actually shouldn't even need to use VSCode yet, though it is encouraged! In other words, you should be able to carry out each of the following tasks solely using the Linux shell which you can access directly within the AWS Console (by right-clicking on your created instance and choosing "Connect"). It is in the *next* homework, **HW2**, where you'll be required to connect to your EC2 instance using VSCode or Positron, so that you can use e.g. `matplotlib` to make time-series plots of this hourly rate!

### Part 1: Downloading Data From an S3 Bucket

First things first, use `mkdir` to create a **subdirectory** within the `dsan6000-hw01-linux-basics` directory called `data`, which is where you will store the hourly data extracts downloaded from the S3 bucket in the next step.

Next, use the `touch` command to create an empty file named `hw01-1-download-data.sh`, which is where your work for the remainder of this step will be saved! After you have created the file with `touch`, use the `chmod` command to modify the permissions for this file to enable **execution** (since, by default, `touch` will only enable reading and writing permissions).

**This last point is important:** everything you do for the remainder of this step, from this point forwards, should **not** be just commands typed directly into the Linux shell! Instead, when you want to write and execute a command, you should adopt the following **workflow**:

1. Open the `hw01-1-download-data.sh` file using Linux's built-in `nano` text editor (via the command `nano hw01-1-download-data.sh`)
2. Enter new commands, or modify existing commands, as needed
3. Use the keyboard shortcut `Ctrl+O` (even on Mac, it is `Ctrl` not `Cmd`!), and then press Enter to save your changes
4. Use the keyboard shortcut `Ctrl+X` to exit the `nano` editor.

Using this workflow, you will be able to edit and save your work in the `.sh` files just as you would edit and save the contents of a `.py` or `.r` file before running it!

With that workflow in mind, your job is now to figure out how to **browse the following S3 bucket**, which contains the hourly data from midnight (EDT) on 31 August 2026 to 11:59pm on 1 September 2026:

```
s3://dsan6000-wikipedia
```

and then **download the `.csv` files** from this bucket into the `data` subdirectory you created above. Specifically:

1. Your `hw01-1-download-data.sh` file should start with a command *listing* the contents of the "folder" (we'll see in class soon why I put "folder" in quotes like this!) within the S3 bucket containing the hourly `.csv` files, and then
2. The file should then contain a second command **copying** the files from the remote S3 bucket to your EC2 instance's `dsan6000-hw01-linux-basics/data` folder.
3. Finally, the last line in the file should be a command that has the effect of listing the files ending in `.csv` that are **within the local `data` folder** (as opposed to step 1, where you listed the *remote* files).

Once you have those three lines in the `.sh` file, run it on your EC2 instance (by just entering and executing `./hw01-1-download-data.sh`), and look at the output it produces (the listing of remote files in the beginning, then the listing of local files at the end) to check that it matches your expectations!

As a final important step in this part, you should now create a **`.gitignore`** file within the **root folder of your cloned GitHub repository**, then use `nano` to edit this file with a line telling Git that you do **not** want it to push **any of the `.csv` files within the `data` subdirectory** to GitHub. That is, your submission's **`data` subfolder should be empty!** The `.sh` files should work such that they **fill** the `data` subfolder when we run them as graders.

To emphasize the importance of this last step: if the GitHub repository that you submit for the assignment has `.csv` files in it, you will have **points deducted** from the submission, since this is very much *not good practice* when working with big data! For very small data sizes, it is sometimes ok to commit your data alongside your code files (something you have done often in previous DSAN assignments, for example!), but in this class it is... not ok! In fact, this practice will become more and more important in later weeks, as we start working with libraries that explicitly require **separation of data files (here, `.csv files) from the computations you'd like to perform on them (here, the `.sh files)**.

### Part 2: Basic Summary Statistics

Since (as mentioned above) next week, in **HW2**, you will be working with this data on EC2 in a Python environment like you are more used to, this part is not meant as a "statistical analysis" of the data.

However, it *is* important for you to be able to use the Linux shell to learn some basic information about the files you just downloaded. Thus, your second (and final) task for this assignment is to **create another `.sh` file, `hw01-2-summarize-data.sh`**, that **processes the `data` subdirectory** by outputting a `.csv` file wherein each row contains the filename, file size, and number of lines for each downloaded data file**.

Specifically, the generated `.csv` file should be called `wikimedia_data_summary.csv`, it should live within the **root folder** of your Git repository (*not* within the `data` subdirectory), and it should have **25 rows**, since there are **24 data files (one per hour)**. The **header row** should label the three columns as `filename`, `size`, and `num_lines`, and then the 24 remaining rows should have:

* `filename` The filename of the `.csv` file. Note that this is *not* the file*path*! There should not be any slashes like `/` in this column. Linux has a command, `basename` that may be helpful for this.
* `size`: The size of the file in **human-readable** format. Within the Linux shell, "human-readable" has a specific meaning: when running the `ls` command, for example, Linux's default behavior is to report the file sizes in **bytes**. If you supply the `-h` flag, however (`ls -h`), these file sizes will instead be reported with a units suffix (`M` for Megabytes, for example), which is how you should record the sizes in this column.
* `num_lines`: An integer representing the total number of lines in the downloaded `.csv` file. The Linux command `wc -l` will be helpful here!

### Part 3: Submission

Once you have completed the above steps, your local repository (on EC2) should contain the following files:

* `README.md` (pre-supplied)
* `recentchange.jpg` (pre-supplied)
* `hw01-1-download-data.sh`
* `hw01-2-summarize-data.sh`
* `wikimedia_data_summary.csv`
* `data` (empty subdirectory)

Since you submitted your GitHub URL all the way up at the top of the instructions, all that is left is for you to **push your work from EC2 to GitHub**. If you push a commit with the commit message **"Final submission"** (by running `git commit -m "Final submission"` and then `git push`), we will consider your repo ready to grade – otherwise, if no commit with this message is found, we will consider the **most recent commit when the due date is reached** to be your final submission.

---

Assignment hash: `c0a2ba6f8a1241246a9db97a9b72b416c15fbde0e34270b48bc82a291fcea3c2`
