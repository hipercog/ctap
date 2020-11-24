import React, { useState, useEffect, useReducer } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { v4 as uuidv4 } from 'uuid';
import { makeStyles } from '@material-ui/core/styles';
import Container from '@material-ui/core/Container';
import Select from '@material-ui/core/Select';
import MenuItem from '@material-ui/core/MenuItem';
import InputLabel from '@material-ui/core/InputLabel';
import FormControl from '@material-ui/core/FormControl';
import TextField from '@material-ui/core/TextField';
import Button from '@material-ui/core/Button';
import BasicInfo from "./BasicInfo";
import LinearTemplate from "./LinearTemplate";
import Steppers from "./Stepper";
import LinearPipesForm from "./LinearPipesForm";

const useStyles = makeStyles((theme) => ({
    formControl: {
        margin: theme.spacing(1),
        minWidth: 200,
    },
    selectEmpty: {
        marginTop: theme.spacing(2),
    },
}));

export default function Main() {
    const classes = useStyles();

    const [inputFields, setInputFields] = useState([{ id: uuidv4(), stepID: '', funcsSettings: [{ fid: uuidv4(), functionName: '', functionP: '' }] }]);
    const [activeStep, setActiveStep] = useState(0);
    const [downloadLink, setDownloadLink] = useState('');
    const [stepNum, setStepNum] = useState(1);
    const [basicInfoInput, setBasicInfoInput] = useReducer(
        (state, newState) => ({ ...state, ...newState }),
        {
            pipelineName: "",
            projectRoot: "",
            sbj_filt: "",
            eegType: "",
            eegChanloc: "",
            eegReference: "",
            eegVeogChannelNames: "",
            eegHeogChannelNames: ""
        }
    );

    //generate stepSet form
    useEffect(() => {
        let form = [];
        console.log(stepNum)
        for (let i = 0; i < stepNum; i++) {
            form.push({ id: uuidv4(), stepID: '', funcsSettings: [{ fid: uuidv4(), functionName: '', functionP: '' }] });
        }
        setInputFields(form);
    }, [])

    // use localstorage save last edit  
    useEffect(() => {
        if (localStorage.getItem("basicInfoInput")) {
            setBasicInfoInput(JSON.parse(localStorage.getItem("basicInfoInput")));
        }
    }, [])
    useEffect(() => {
        localStorage.setItem("basicInfoInput", JSON.stringify(basicInfoInput))
    }, [basicInfoInput])

    // make text file
    const makeTextFile = (basicInfoInput, inputFields) => {
        console.log(inputFields);
        let list = LinearTemplate(basicInfoInput, inputFields)
        const data = new Blob([list.join('\n')], { type: 'text/plain' })
        if (downloadLink !== '') window.URL.revokeObjectURL(downloadLink)
        setDownloadLink(window.URL.createObjectURL(data))
    };
    useEffect(() => {
        console.log('???')
        makeTextFile(basicInfoInput, inputFields)
    }, [basicInfoInput, inputFields])

    //handle input change
    const handleInput = event => {
        const { name, value } = event.target;
        setBasicInfoInput({ [name]: value });
    };

    //steppers handler
    const handleNext = () => {
        setActiveStep((prevActiveStep) => prevActiveStep + 1);
    };
    const handleBack = () => {
        setActiveStep((prevActiveStep) => prevActiveStep - 1);
    };
    const handleReset = () => {
        setActiveStep(0);
    };

    // LinearPipesForm handles
    const handleSubmit = (e) => {
        e.preventDefault();
        console.log("InputFields", inputFields);
    };

    const handleLinearPipesInput = (id, event) => {
        const newInputFields = inputFields.map(i => {
            if (id === i.id) {
                i[event.target.name] = event.target.value
            }
            return i;
        })
        setInputFields(newInputFields);
    }

    const handleFuncsSettingInput = (mid, id, event) => {
        console.log(event.target.value)
        const values = [...inputFields];
        let index = values.findIndex(x => x.id === mid);
        const newInputFields = values[index].funcsSettings.map(i => {
            if (id === i.fid) {
                i[event.target.name] = event.target.value
            }
            return i;
        })
        console.log(newInputFields)
        values[index].funcsSettings = newInputFields;
        setInputFields(values);
    }

    const handleAddFuncFields = id => {
        const values = [...inputFields];
        let index = values.findIndex(x => x.id === id);
        values[index].funcsSettings.push({ fid: uuidv4(), functionName: '', functionP: '' });
        setInputFields(values);
    }

    const handleRemoveFuncFields = (mid, id) => {
        const values = [...inputFields];
        let index = values.findIndex(x => x.id === mid);
        let indexf = values[index].funcsSettings.findIndex(x => x.fid === id);
        values[index].funcsSettings.splice(indexf, 1);
        setInputFields(values);
    }

    const handleChangeStepSets = (e) => {
        const { name, value } = e.target;

        if (stepNum < value) {
            let form = [...inputFields];
            for (let i = stepNum; i < value; i++) {
                form.push({ id: uuidv4(), stepID: '', funcsSettings: [{ fid: uuidv4(), functionName: '', functionP: '' }] });
            }
            setInputFields(form);
            setStepNum(value);
        } else if (stepNum > value && value >=1) {
            let form = [...inputFields];
            for (let i = 0; i < stepNum-value; i++) {
                form.pop();
            }
            setInputFields(form);
            setStepNum(value);
        }
    }


    return (
        <div>
            <div>
                <span>CTAP Code Generation Tool</span>

                {activeStep === 0 ? (
                    <BasicInfo
                        InputValue={basicInfoInput}
                        handleInput={handleInput}
                    />
                ) : activeStep === 1 ? (
                    <Container>
                        <h1>Linear Pipeline Setting</h1>
                        <FormControl variant="outlined" className={classes.formControl}>
                            <InputLabel >stepSet number</InputLabel>
                            <Select
                                native
                                value={stepNum}
                                onChange={e => handleChangeStepSets(e)}
                                label="stepSet number"
                                inputProps={{
                                    name: 'stepNum',
                                }}
                            >
                                {
                                    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(i => {
                                        return <option key={i} value={i}>{i}</option>
                                    })
                                }
                            </Select>
                        </FormControl>
                        <LinearPipesForm
                            inputFields={inputFields}
                            handleAddFuncFields={handleAddFuncFields}
                            handleRemoveFuncFields={handleRemoveFuncFields}
                            handleLinearPipesInput={handleLinearPipesInput}
                            handleSubmit={handleSubmit}
                            handleFuncsSettingInput={handleFuncsSettingInput}
                        />
                    </Container>
                ) : activeStep === 2 ? (
                    <div>
                        <a
                            download='ctap_linear_template.m'
                            href={downloadLink}
                        >
                            download
                        </a>
                    </div>


                ) : null

                }

            </div>
            <Steppers
                activeStep={activeStep}
                handleBack={handleBack}
                handleNext={handleNext}
                handleReset={handleReset}
            />

        </div>
    );




}