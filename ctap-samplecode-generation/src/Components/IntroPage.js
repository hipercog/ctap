import React, { useState, useEffect } from "react";
import {Link} from "react-router-dom"
import Container from '@material-ui/core/Container';
import { makeStyles } from '@material-ui/core/styles';
import Stepper from '@material-ui/core/Stepper';
import Step from '@material-ui/core/Step';
import StepLabel from '@material-ui/core/StepLabel';
import StepContent from '@material-ui/core/StepContent';
import Button from '@material-ui/core/Button';
import Paper from '@material-ui/core/Paper';
import Check from "@material-ui/icons/Check";
import clsx from "clsx";
import Typography from "@material-ui/core/Typography";

const useStyles = makeStyles((theme) => ({
    root: {
        width: '100%',
        marginTop: 50
    },
    button: {
        marginTop: theme.spacing(1),
        marginRight: theme.spacing(1),
    },
    actionsContainer: {
        marginBottom: theme.spacing(2),
    },
    resetContainer: {
        padding: theme.spacing(3),
    },
    nav:{ 
        color: 'inherit', 
        textDecoration: "underline",
        fontStyle:"italic"
    }
}));

export const useQontoStepIconStyles = makeStyles({
    root: {
        color: "#eaeaf0",
        display: "flex",
        height: 30,
        alignItems: "center"
    },
    active: {
        color: "#784af4"
    },
    circle: {
        width: 24,
        height: 24,
        borderRadius: "50%",
        backgroundColor: "currentColor"
    },
    completed: {
        color: "#784af4",
        zIndex: 1,
        fontSize: 24
    }
});

function QontoStepIcon(props) {
    const classes = useQontoStepIconStyles();
    const { active, completed } = props;

    return (
        <div
            className={clsx(classes.root, {
                [classes.active]: active
            })}
        >
            {completed ? (
                <Check className={classes.completed} />
            ) : (
                    <div className={classes.circle} />
                )}
        </div>
    );
}

function getSteps() {
    return ['Get CTAP Ready', 'Create Execution Folder', 'Instructions on Required Files'];
}

function getStepContent(step) {
    switch (step) {
        case 0:
            return (
                <div style={{ marginLeft: '2rem', marginTop: '1rem' }}>
                    <Typography variant="body1" align="left">1. Follow the instruction of <a rel="noreferrer" target="_blank" href="https://github.com/bwrc/ctap">the CTAP repo</a>, download CTAP and setup your MATLAB work environment</Typography>
                    <Typography variant="body1" align="left">2. You also need to have latest EEGLAB added to your Matlab path (<a rel="noreferrer" target="_blank" href='https://sccn.ucsd.edu/eeglab/downloadtoolbox.php'>instructions here</a>).</Typography>
                </div>
            );
        case 1:
            return (
                <div style={{ marginLeft: '2rem', marginTop: '1rem' }}>
                    <Typography variant="body1" align="left">Create a new project folder under <i><b>~/ctap/templates</b></i> as execution folder. Later after code generation, put the generated executable .m file into this folder.</Typography>
                </div>
            );
        case 2:
            return (
                <div style={{ marginLeft: '2rem', marginTop: '1rem' }}>
                    <Typography variant="body1" align="left">1. The default data source path is <i><b>~/ctap/data/test_data</b></i>.</Typography>
                    <Typography variant="body2" align="left">You can use defalut path by copying your data into default folder, or you can also define your own data path later</Typography>
                    <Typography variant="body1" align="left">2. CTAP provides various choices on channel location files, you can find them at <i><b>~/ctap/res</b></i>.</Typography>
                    <Typography variant="body2" align="left">You can also specify your own channel location file, please copy it to  <i><b>~/ctap/res</b></i>, and add its name manually in the later process.</Typography>
                </div>
            );
        default:
            return 'Unknown step';
    }
}

const IntroPage = () => {
    const classes = useStyles();
    const [activeStep, setActiveStep] = React.useState(0);
    const steps = getSteps();

    const handleNext = () => {
        setActiveStep((prevActiveStep) => prevActiveStep + 1);
    };

    const handleBack = () => {
        setActiveStep((prevActiveStep) => prevActiveStep - 1);
    };

    const handleReset = () => {
        setActiveStep(0);
    };

    return (
        <Container maxWidth="sm">
            <div style={{ float:'center', margin: 30}} >
                    <Link className={classes.nav} to="/">Intro Page ᐊ</Link>
                    <a>  /  </a>
                    <Link className={classes.nav} to="/start"> Info Form ᐊ</Link>
            </div>
            <div style={{ marginTop: 70 }}>
                <Typography variant='h5'>The CTAP Code Generation Tool is used to show users how CTAP code works and some core ideas of CTAP programming.</Typography>
            </div>
            <div className={classes.root}>
                <Stepper activeStep={activeStep} orientation="vertical">
                    {steps.map((label, index) => (
                        <Step key={label}>
                            <StepLabel StepIconComponent={QontoStepIcon}><Typography variant="h6">{label}</Typography></StepLabel>
                            <StepContent>
                                {getStepContent(index)}
                                <div className={classes.actionsContainer}>
                                    <div style={{ marginTop: '1rem' }}>
                                        <Button
                                            disabled={activeStep === 0}
                                            onClick={handleBack}
                                            className={classes.button}
                                        >
                                            Back
                                        </Button>
                                        <Button
                                            variant="contained"
                                            color="primary"
                                            onClick={handleNext}
                                            className={classes.button}
                                        >
                                            { 'Next'}
                                        </Button>
                                    </div>
                                </div>
                            </StepContent>
                        </Step>
                    ))}
                </Stepper>
                {activeStep === steps.length && (
                    <Paper square elevation={0} className={classes.resetContainer}>
                        <Typography variant='h6'>All steps completed - Now Let's step to</Typography>
                        <Typography variant='h6'>CTAP CODE GNERATION!</Typography>
                        <div style={{ marginTop: '1rem' }}>
                            <Button onClick={handleReset} className={classes.button}>
                                Reset
                            </Button>
                            <Button
                                variant="contained"
                                color="primary"
                                className={classes.button}
                            ><Link to="/start" style={{ textDecoration: 'none', color: 'inherit' }}>
                                    Proceed
                            </Link>
                            </Button>
                        </div>

                    </Paper>
                )}
            </div>
        </Container>

    )
}

export default IntroPage;