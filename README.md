# ayoubMah.github.io

This project is a personal website built using Jekyll, a static site generator. The site is designed to showcase the work and interests of Ayoub Mahjouby, a computer science student.

## Project Structure

- **_config.yml**: Contains configuration settings for the Jekyll site, including site name, description, avatar URL, and social media links.
- **style.scss**: The main stylesheet for the project, importing reset styles, variables, and syntax highlighting. It defines base styles for HTML elements and layout sections, with responsive design elements.
- **svg-icons/**: A directory for storing SVG icon files that can be used throughout the site.
- **highlights/**: A directory for storing syntax highlighting styles or files related to code highlighting.
- **variables/**: A directory for storing SCSS variables that define colors, fonts, and other design tokens used throughout the styles.

## Setup Instructions

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/ayoubMah.github.io.git
   cd ayoubMah.github.io
   ```

2. **Install Dependencies**:
   Make sure you have Ruby and Bundler installed. Then run:
   ```bash
   bundle install
   ```

3. **Run the Jekyll Server**:
   Start the Jekyll server to view your site locally:
   ```bash
   bundle exec jekyll serve
   ```

4. **Open in Browser**:
   Navigate to `http://localhost:4000` to see your site in action.

## Customization

You can customize the site by editing the `_config.yml` file to change the site name, description, and social media links. Modify the `style.scss` file to adjust the styles according to your preferences.

## License

This project is open-source and available under the MIT License.