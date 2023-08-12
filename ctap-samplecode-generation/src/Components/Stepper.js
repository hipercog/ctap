import React, { useContext } from "react";
import Button from '@material-ui/core/Button';
import clsx from "clsx";
import Stepper from "@material-ui/core/Stepper";
import Step from "@material-ui/core/Step";
import StepLabel from "@material-ui/core/StepLabel";
import Check from "@material-ui/icons/Check";
import {useStyles, useQontoStepIconStyles, QontoConnector} from '../Styles/StepperStyles'
import { ContextBasic } from '../Reducers/ContextProvider'

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
    return ["Basic settings", "Pipe config", "Review and download"];
}

const Steppers = ({ activeStep, handleSubmit, handleReset, handleBack, handleNext, isReadyDownload, downloadLink }) => {
    const classes = useStyles();
    const steps = getSteps();
    const [basicInfoInput, dispatch] = useContext(ContextBasic);

    let downloadName = basicInfoInput.pipelineName + '.m'

    return (
        <div className={classes.root}>
            <div>
                {activeStep === steps.length ? (
                    <div>
                        {isReadyDownload ?
                            <div>
                                <div style={{ margin: 50 }}>
                                    <Button download={downloadName} href={downloadLink} variant="outlined" color="primary">Download</Button>
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