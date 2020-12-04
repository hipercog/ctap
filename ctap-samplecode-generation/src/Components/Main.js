import React, { useState, useEffect, useReducer, useContext } from "react";
import { v4 as uuidv4 } from 'uuid';
import { makeStyles } from '@material-ui/core/styles';
import Container from '@material-ui/core/Container';
import Select from '@material-ui/core/Select';
import InputLabel from '@material-ui/core/InputLabel';
import FormControl from '@material-ui/core/FormControl';
import Button from '@material-ui/core/Button';
import BasicInfo from "./BasicInfo";
import LinearTemplate from "./LinearTemplate";
import Steppers from "./Stepper";
import LinearPipesForm from "./LinearPipesForm";
import BranchPipesForm from "./BranchPipesForm";
import BranchTemplate from "./BranchTemplate"

import { Context } from './ContextProvider'

const useStyles = makeStyles((theme) => ({
    formControl: {
        margin: theme.spacing(1),
        minWidth: 200,
    },
    selectEmpty: {
        marginTop: theme.spacing(2),
    },

    button: {
        margin: theme.spacing(2),
    }
}));

export default function Main() {
    const classes = useStyles();

    const [inputStates, dispatch] = useContext(Context);
    const [activeStep, setActiveStep] = useState(0);
    const [downloadLink, setDownloadLink] = useState('');
    const [stepNum, setStepNum] = useState(1);
    const [isReadyDownload, setIsReadyDownload] = useState(false);
    const [basicInfoInput, setBasicInfoInput] = useReducer(
        (state, newState) => ({ ...state, ...newState }),
        {
            checkedLinear: true,
            checkedBranch: false,
            checkedHYDRA: true,
            HydraOptionA: true,
            HydraOptionB: false,
            checkHydraTimeRange: "",
            checkHydraCleanSeed: "",
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
    const [basicInfoInputCheck, setBasicInfoInputCheck] = useReducer(
        (state, newState) => ({ ...state, ...newState }),
        {
            checkHydraTimeRange: false,
            checkHydraCleanSeed: false,
            pipelineName: false,
            projectRoot: false,
            sbj_filt: false,
            eegType: false,
            eegChanloc: false,
            eegReference: false,
            eegVeogChannelNames: false,
            eegHeogChannelNames: false
        }
    );

    useEffect(() => {
        setDownloadLink('');
        setIsReadyDownload(false);
    }, [basicInfoInput.checkedLinear])

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
    const makeTextFile = (basicInfoInput, inputStates) => {
        let list;
        if (basicInfoInput.checkedLinear) {
            list = LinearTemplate(basicInfoInput, inputStates);
        } else {
            list = BranchTemplate(basicInfoInput, inputStates);
        };
        const data = new Blob([list.join('\n')], { type: 'text/plain' });
        if (downloadLink !== '') window.URL.revokeObjectURL(downloadLink);
        return window.URL.createObjectURL(data);

    };

    //input check
    const inputCheck = () => {
        let result = true;
        let newS = {};
        if (activeStep === 0) {
            const values = { ...basicInfoInputCheck }
            for (const [key, value] of Object.entries(values)) {
                if (basicInfoInput[key] === null || basicInfoInput[key].length === 0) {
                    if (key === 'checkHydraTimeRange' && basicInfoInput.HydraOptionB) {
                        newS = { ...newS, [key]: false };
                    } else if (key === 'checkHydraCleanSeed' && basicInfoInput.HydraOptionA) {
                        newS = { ...newS, [key]: false };
                    }
                    else {
                        newS = { ...newS, [key]: true };
                    }
                }
            }
            result = Object.values(newS).every((value) => value === false);
            setBasicInfoInputCheck({ ...basicInfoInputCheck, ...newS });
        }else if(activeStep === 1){
            const value = {...inputStates}
            const newInputFields = inputStates.map(i => {
                i.stepID.length ? i.stepIDCheck=false : ( ()=>{i.stepIDCheck=true; result=false})()
                if(basicInfoInput.checkedBranch){
                    i.subf_srcid.length ? i.subf_srcidCheck=false : ( ()=>{i.subf_srcidCheck=true; result=false})();
                    i.subfID.length ? i.subfIDCheck=false : ( ()=>{i.subfIDCheck=true; result=false})()
                }
                i.funcsSettings.map(f=>{
                    f.funcName.length ? f.funcNameCheck=false : ( ()=>{f.funcNameCheck=true; result=false})()
                })
                return i;
            })
            dispatch({ type: 'UPDATE_STEPSETS', data: newInputFields })
        }

        return result;
    }

    //steppers handler
    const handleNext = () => {
        let p = inputCheck();
        if (p) {
            setActiveStep((prevActiveStep) => prevActiveStep + 1);
        } else {
            alert("check your input");
        }

    };
    const handleBack = () => {
        setActiveStep((prevActiveStep) => prevActiveStep - 1);
    };
    const handleReset = () => {
        setActiveStep(0);
    };

    // LinearPipesForm handles
    async function handleSubmit() {
        let downloadlink = await makeTextFile(basicInfoInput, inputStates);
        setDownloadLink(downloadlink);
        setIsReadyDownload(true);
    };

    const handleLinearPipesInput = (id, event) => {
        const newInputFields = inputStates.map(i => {
            if (id === i.id) {
                i[event.target.name] = event.target.value
                i[event.target.name + 'Check'] = false;
            }
            return i;
        })
        dispatch({ type: 'UPDATE_STEPSETS', data: newInputFields })
    }

    const handleChangeStepSets = (e) => {
        const { name, value } = e.target;

        if (stepNum < value) {
            let form = [...inputStates];
            for (let i = stepNum; i < value; i++) {
                form.push({ id: uuidv4(), subf_srcid: '', subfID: '', stepID: '', funcsSettings: [{ fid: uuidv4(), funcName: '', funcP: '' }] });
            }
            dispatch({ type: 'UPDATE_STEPSETS', data: form })
            setStepNum(value);
        } else if (stepNum > value && value >= 1) {
            console.log(value);
            console.log(stepNum)
            console.log(inputStates)
            let form = [...inputStates];
            for (let i = 0; i < stepNum - value; i++) {
                form.pop();
            }
            console.log(form)
            dispatch({ type: 'UPDATE_STEPSETS', data: form })
            setStepNum(value);
        }
    }


    return (
        <div>
            <div>
                <span>CTAP Code Generation Tool</span>

                {activeStep === 0 ? (
                    <BasicInfo
                        inputValue={basicInfoInput}
                        setBasicInfoInput={setBasicInfoInput}
                        basicInfoInputCheck={basicInfoInputCheck}
                        setBasicInfoInputCheck={setBasicInfoInputCheck}
                    />
                ) : activeStep === 1 ? (
                    <Container>
                        {basicInfoInput.checkedLinear ?
                            <h1>Linear Pipeline Setting</h1>
                            :
                            <h1>Branch Pipeline Setting</h1>}

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
                        {basicInfoInput.checkedLinear ?
                            <LinearPipesForm
                                handleLinearPipesInput={handleLinearPipesInput}
                                handleSubmit={handleSubmit} />
                            :
                            <BranchPipesForm
                                handleLinearPipesInput={handleLinearPipesInput}
                                handleSubmit={handleSubmit} />}

                    </Container>
                ) : activeStep === 2 ? (
                    <div>
                        <Button
                            className={classes.button}
                            variant="contained"
                            color="primary"
                            type="submit"
                            onClick={handleSubmit}
                        >Generate</Button>
                        <div>
                            {isReadyDownload ?
                                <a download='ctap_linear_template.m' href={downloadLink} className={classes.downloadButton}> download </a> : null
                            }
                        </div>


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