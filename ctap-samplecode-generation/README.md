## About
This is CTAP code generation, a web tool to help users generate CTAP scripts and get to know the basic content of CTAP in an interactive way.

## Link to running application
[CTAP code generation tool](https://ruoyanmeng.github.io/ctap/#/)

## To start a local version
To start a local version, download and run:
<pre><code>npm install</code></pre>
<pre><code>npm start</code></pre>

## Deploy on Github page
<pre><code>npm run deploy</code></pre>

## File Architecture
```
├── README.md
├── package-lock.json
├── package.json
├── public
│   └── index.html
└── src
    ├── Components // Presentational pages and logic operation containers
    │   ├── BasicInfo.js 
    │   ├── BranchPipesForm.js
    │   ├── BranchTemplate.js
    │   ├── FuncsSettingForm.js
    │   ├── IntroPage.js
    │   ├── LinearPipesForm.js
    │   ├── Main.js // main container for different pesentational pages
    │   ├── ReviewPage.js
    │   └── Stepper.js
    ├── Data // option data for CTAP functions and CTAP EEG channel locations
    │   ├── CTAP_chanlocs.js 
    │   └── CTAP_funcs.js
    │── img 
    │   ├── CTAP_Branch.png
    │   ├── CTAP_HYDRA.jpg
    │   └── CTAP_Linear.png
    ├── Reducers // Provide required states to different pages
    │   ├── ContextProvider.js   
    │   └── Reducer.js
    ├── Styles
    │   ├── FormControlStyles.js
    │   ├── IntroStyle.js
    │   ├── MainStyles.js
    │   └── StepperStyles.js
    ├── App.js // Router
    └── index.js // Render hole APP
```

### Frameworks used
* ReactJS

### Libraries used
* material-ui
* react-syntax-highlighter
* react-router-dom
* uuid
