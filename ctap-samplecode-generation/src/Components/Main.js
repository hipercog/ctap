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

import { ContextBranch, ContextLinear } from './ContextProvider'

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

    const [inputLinearStates, dispatchL] = useContext(ContextLinear);
    const [inputBranchStates, dispatchB] = useContext(ContextBranch);
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

    const [inputStates, setInputStates] = useState(() => {
        if (basicInfoInput.checkedLinear) {
            return inputLinearStates;
        } else {
            return inputBranchStates;
        }
    });


    useEffect(() => {
        if (basicInfoInput.checkedLinear) {
            setInputStates(inputLinearStates);
        } else {
            setInputStates(inputBranchStates);
        }
    }, [basicInfoInput.checkedLinear, inputLinearStates, inputBranchStates])

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
                    if (basicInfoInput.checkedHYDRA) {
                        if (key === 'checkHydraTimeRange' && basicInfoInput.HydraOptionB) {
                            newS = { ...newS, [key]: false };
                        } else if (key === 'checkHydraCleanSeed' && basicInfoInput.HydraOptionA) {
                            newS = { ...newS, [key]: false };
                        }else{
                            newS = { ...newS, [key]: true };
                        }
                    } else {
                        if (key === 'checkHydraTimeRange' || key === 'checkHydraCleanSeed') {
                            newS = { ...newS, [key]: false };
                        } else {
                            newS = { ...newS, [key]: true };
                        }
                    }
                }
            }
            result = Object.values(newS).every((value) => value === false);
            setBasicInfoInputCheck({ ...basicInfoInputCheck, ...newS });
        } else if (activeStep === 1) {
            const newInputFields = inputStates.map((i,index) => {
                console.log(i);
                i.stepID.length ? i.stepIDCheck = false : (() => { i.stepIDCheck = true; result = false })()
                if (basicInfoInput.checkedBranch) {
                    if(index === 0){
                        i.pipeSegment_srcidCheck = false;
                        result = true;
                        i.pipeSegmentID.length ? i.pipeSegmentIDCheck = false : (() => { i.pipeSegmentIDCheck = true; result = false })()
                    }else{
                        i.pipeSegment_srcid.length ? i.pipeSegment_srcidCheck = false : (() => { i.pipeSegment_srcidCheck = true; result = false })();
                        i.pipeSegmentID.length ? i.pipeSegmentIDCheck = false : (() => { i.pipeSegmentIDCheck = true; result = false })()
                    }
                }
                i.linearSetting.forEach(l => {
                    l.funcsSettings.forEach(f => {
                        f.funcName.length ? f.funcNameCheck = false : (() => { f.funcNameCheck = true; result = false })()
                    })
                })
                return i;
            })
            dispatchL({ type: 'UPDATE_STEPSETS', data: newInputFields })
        }

        return result;
    }

    //steppers handler
    const handleNext = () => {
        //first run input check
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

    const handleChangeStepSets = (e) => {
        const { value } = e.target;
        if (stepNum < value) {
            let form = [...inputStates];
            if (basicInfoInput.checkedLinear) {
                for (let i = stepNum; i < value; i++) {
                    form.push({ id: uuidv4(), stepID: '', stepIDCheck: false, funcsSettings: [{ fid: uuidv4(), funcName: '', funcP: '', funcNameCheck: false }] });
                }
                dispatchL({ type: 'UPDATE_STEPSETS', data: form })
            } else { 
                for (let i = stepNum; i < value; i++) {
                    form.push({ id: uuidv4(), pipeSegment_srcid: '', pipeSegmentID: '', stepID: '', pipeSegment_srcidCheck:false, pipeSegmentIDCheck:false, stepIDCheck:false, linearSetting:[{ id: uuidv4(), stepID: '', stepIDCheck:false, funcsSettings: [{ fid: uuidv4(), funcName: '', funcP: '', funcNameCheck:false}] }] });
                }
                console.log(form)
                dispatchB({ type: 'UPDATE_STEPSETS', data: form })
            }
            setStepNum(value);
        } else if (stepNum > value && value >= 1) {
            console.log(inputStates)
            let form = [...inputStates];
            for (let i = 0; i < stepNum - value; i++) {
                form.pop();
            }
            if(basicInfoInput.checkedLinear){
                dispatchL({ type: 'UPDATE_STEPSETS', data: form });
            }else{
                dispatchB({ type: 'UPDATE_STEPSETS', data: form })
            }
            setStepNum(value);
        }
    }

    


    return (
        <div>
            <div>
                

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
                            <h3>Linear Pipeline Setting</h3>
                            :
                            <h3>Branch Pipeline Setting</h3>}

                        <FormControl variant="outlined" className={classes.formControl}>
                        <InputLabel > {basicInfoInput.checkedBranch ? 'pipeSegments' : 'stepSet number' }</InputLabel>
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
                                ifLinear={true}
                                index={0}
                                mid={0} />
                            :
                            <BranchPipesForm />}

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