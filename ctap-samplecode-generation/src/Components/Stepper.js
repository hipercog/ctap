import { makeStyles, withStyles } from "@material-ui/core/styles";
import StepConnector from "@material-ui/core/StepConnector";
import Button from '@material-ui/core/Button';
import clsx from "clsx";
import Stepper from "@material-ui/core/Stepper";
import Step from "@material-ui/core/Step";
import StepLabel from "@material-ui/core/StepLabel";
import Check from "@material-ui/icons/Check";


export const QontoConnector = withStyles({
    alternativeLabel: {
        top: 10,
        left: "calc(-50% + 16px)",
        right: "calc(50% + 16px)"
    },
    active: {
        "& $line": {
            borderColor: "#784af4"
        }
    },
    completed: {
        "& $line": {
            borderColor: "#784af4"
        }
    },
    line: {
        borderColor: "#eaeaf0",
        borderTopWidth: 3,
        borderRadius: 1
    },
})(StepConnector);

export const useQontoStepIconStyles = makeStyles({
    root: {
        color: "#eaeaf0",
        display: "flex",
        height: 22,
        alignItems: "center"
    },
    active: {
        color: "#784af4"
    },
    circle: {
        width: 8,
        height: 8,
        borderRadius: "50%",
        backgroundColor: "currentColor"
    },
    completed: {
        color: "#784af4",
        zIndex: 1,
        fontSize: 18
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

const useStyles = makeStyles((theme) => ({
    root: {
        width: "100%",
        marginTop: 50
    },
    button: {
        marginRight: theme.spacing(1),
        marginBottom: theme.spacing(2),
    },
    instructions: {
        marginTop: theme.spacing(1),
        marginBottom: theme.spacing(1)
    },

}));

function getSteps() {
    return ["Basic settings", "Pipe config", "Review and download"];
}

const Steppers = ({ activeStep, handleSubmit, handleReset, handleBack, handleNext, isReadyDownload, downloadLink }) => {
    const classes = useStyles();
    const steps = getSteps();


    return (
        <div className={classes.root}>
            <div>
                {activeStep === steps.length ? (
                    <div>
                        {isReadyDownload ?
                            <div>
                                <div style={{ margin: 50 }}>
                                    <Button download='ctap_linear_template.m' href={downloadLink} variant="outlined" color="primary">Download</Button>
                                </div>
                                <Button variant="outlined" color="secondary" onClick={handleReset} className={classes.button}>
                                    Reset
                                    </Button>
                                <Button variant="contained" onClick={handleBack} className={classes.button} color="primary">
                                    Back
                                    </Button>
                            </div> : null}
                    </div>
                ) : (
                        <div>
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
                                {activeStep === steps.length - 1 ? "Finish and Generate Code" : "Next"}
                            </Button>
                        </div>
                    )}
            </div>
            <Stepper
                alternativeLabel
                activeStep={activeStep}
                connector={<QontoConnector />}
            >
                {steps.map((label) => (
                    <Step key={label}>
                        <StepLabel StepIconComponent={QontoStepIcon}>{label}</StepLabel>
                    </Step>
                ))}
            </Stepper>
        </div>
    );
}

export default Steppers;