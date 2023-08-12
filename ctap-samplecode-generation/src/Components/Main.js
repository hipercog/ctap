import React, { useState, useEffect, useReducer, useContext } from "react";
import { v4 as uuidv4 } from 'uuid';
import { Link } from "react-router-dom"

import Container from '@material-ui/core/Container';
import Select from '@material-ui/core/Select';
import InputLabel from '@material-ui/core/InputLabel';
import FormControl from '@material-ui/core/FormControl';
import BasicInfo from "./BasicInfo";
import LinearTemplate from "./LinearTemplate";
import Steppers from "./Stepper";
import LinearPipesForm from "./LinearPipesForm";
import BranchPipesForm from "./BranchPipesForm";
import BranchTemplate from "./BranchTemplate"
import ReviewPage from "./ReviewPage"
import { ContextBranch, ContextLinear, ContextBasic } from '../Reducers/ContextProvider'
import {initialLinearInputState, initialBranchInputState, defaultBasicInfoInput} from '../Reducers/Reducer'
import {MainStyles} from '../Styles/MainStyles'


export default function Main() {
    const classes = MainStyles();

    const [inputLinearStates, dispatchL] = useContext(ContextLinear);
    const [inputBranchStates, dispatchB] = useContext(ContextBranch);
    const [basicInfoInput, dispatch] = useContext(ContextBasic);

    const [activeStep, setActiveStep] = useState(0);
    const [downloadLink, setDownloadLink] = useState('');
    const [stepNum, setStepNum] = useState(1);
    const [isReadyDownload, setIsReadyDownload] = useState(false);
    const [codeString, setCodeString] = useState('');
    const [basicInfoInputCheck, setBasicInfoInputCheck] = useReducer(
        (state, newState) => ({ ...state, ...newState }),
        {
            checkHydraTimeRange: false,
            checkHydraCleanSeed: false,
            pipelineName: false,
            inputdatapath: false,
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
        };
    });

    // Listen if Linear or Branch pipeline
    useEffect(() => {
        if (basicInfoInput.checkedLinear) {
            setInputStates(inputLinearStates);
        } else {
            setInputStates(inputBranchStates);
        };
    }, [inputLinearStates, inputBranchStates]); // eslint-disable-line react-hooks/exhaustive-deps

    // Reset pipeline states everytime Linear/Branch option change
    useEffect(() => {
        setStepNum(1);
        if (basicInfoInput.checkedLinear) {
            let initialLinear = [{ id: uuidv4(), stepID: '', stepIDCheck: false, funcsSettings: [{ fid: uuidv4(), funcName: '', funcP: '', funcNameCheck: false }] }];
            dispatchL({ type: 'UPDATE', data: initialLinear });
            setInputStates(initialLinear);
        } else {
            let initialBranch = [{ id: uuidv4(), stepNum: 1, pipeSegment_srcid: '', pipeSegmentID: '', stepID: '', pipeSegment_srcidCheck: false, pipeSegmentIDCheck: false, stepIDCheck: false, linearSettings: [{ id: uuidv4(), stepID: '', stepIDCheck: false, funcsSettings: [{ fid: uuidv4(), funcName: '', funcP: '', funcNameCheck: false }] }] }];
            dispatchB({ type: 'UPDATE', data: initialBranch });
            setInputStates(initialBranch);
        };
        setDownloadLink('');
        setIsReadyDownload(false);
    }, [basicInfoInput.checkedLinear]); // eslint-disable-line react-hooks/exhaustive-deps

    // use localstorage save last edit  
    useEffect(() => {
        if (localStorage.getItem("basicInfoInput")) {
            dispatch({ type: 'UPDATE', data: JSON.parse(localStorage.getItem("basicInfoInput")) });
        }
    }, []); // eslint-disable-line react-hooks/exhaustive-deps
    useEffect(() => {
        localStorage.setItem("basicInfoInput", JSON.stringify(basicInfoInput))
    }, [basicInfoInput]); // eslint-disable-line react-hooks/exhaustive-deps

    // make downloadable text file
    const makeTextFile = (basicInfoInput, inputStates) => {
        let list;
        if (basicInfoInput.checkedLinear) {
            list = LinearTemplate(basicInfoInput, inputStates);
        } else {
            list = BranchTemplate(basicInfoInput, inputStates);
        };

        const data = new Blob([list.join('\n')], { type: 'text/plain' });
        setCodeString(list.join('\n'));
        if (downloadLink !== '') window.URL.revokeObjectURL(downloadLink);
        return window.URL.createObjectURL(data);
    };

    //input check
    const inputCheck = () => {
        let result = true;
        let newS = {};
        if (activeStep === 0) {
            const values = { ...basicInfoInputCheck };
            for (const key of Object.keys(values)) {
                if (basicInfoInput[key] === null || basicInfoInput[key].length === 0) {
                    if (basicInfoInput.checkedHYDRA) {
                        if (key === 'checkHydraTimeRange' && basicInfoInput.HydraOptionB) {
                            newS = { ...newS, [key]: false };
                        } else if (key === 'checkHydraCleanSeed' && basicInfoInput.HydraOptionA) {
                            newS = { ...newS, [key]: false };
                        } else {
                            newS = { ...newS, [key]: true };
                        };
                    } else {
                        if (key === 'checkHydraTimeRange' || key === 'checkHydraCleanSeed') {
                            newS = { ...newS, [key]: false };
                        } else {
                            newS = { ...newS, [key]: true };
                        };
                    };
                };
            };
            result = Object.values(newS).every((value) => value === false);
            setBasicInfoInputCheck({ ...basicInfoInputCheck, ...newS });
        } else if (activeStep === 1) {
            const newInputFields = inputStates.map((i, index) => {
                i.stepID.length ? i.stepIDCheck = false : (() => { i.stepIDCheck = true; result = false })();
                if (basicInfoInput.checkedBranch) {
                    if (index === 0) {
                        i.pipeSegment_srcidCheck = false;
                        result = true;
                        i.pipeSegmentID.length ? i.pipeSegmentIDCheck = false : (() => { i.pipeSegmentIDCheck = true; result = false })();
                    } else {
                        i.pipeSegment_srcid.length ? i.pipeSegment_srcidCheck = false : (() => { i.pipeSegment_srcidCheck = true; result = false })();
                        i.pipeSegmentID.length ? i.pipeSegmentIDCheck = false : (() => { i.pipeSegmentIDCheck = true; result = false })();
                    };
                    i.linearSettings.forEach(l => {
                        l.stepID.length ? l.stepIDCheck = false : (() => { l.stepIDCheck = true; result = false })();
                        l.funcsSettings.forEach(f => {
                            let funcEmpty = f.funcName == null || f.funcName.length;
                            funcEmpty ? f.funcNameCheck = false : (() => { f.funcNameCheck = true; result = false })();
                        });
                    });
                } else {
                    i.funcsSettings.forEach(f => {
                        f.funcName.length ? f.funcNameCheck = false : (() => { f.funcNameCheck = true; result = false })();
                    })
                };
                return i;
            });
            dispatchL({ type: 'UPDATE', data: newInputFields });
        };
        return result;
    };

    //steppers handler
    const handleNext = () => {
        //first run input check
        let p = inputCheck();
        if (p) {
            let prevActiveStep = activeStep;
            setActiveStep(prevActiveStep + 1);
            if (prevActiveStep === 1) {
                handleSubmit();
            };
        } else {
            alert("check your input");
        };
    };
    const handleBack = () => {
        let prevActiveStep = activeStep;
        if(prevActiveStep === 3){
            setActiveStep((prevActiveStep) => prevActiveStep - 2);
        }else{
            setActiveStep((prevActiveStep) => prevActiveStep - 1);
        };
    };
    const handleReset = () => {
        setActiveStep(0);
        dispatch({ type: 'UPDATE', data: defaultBasicInfoInput });
        dispatchB({ type: 'UPDATE', data: initialBranchInputState });
        dispatchL({ type: 'UPDATE', data: initialLinearInputState });
    };

    // set downloadlink
    async function handleSubmit() {
        let downloadlink = await makeTextFile(basicInfoInput, inputStates);
        setDownloadLink(downloadlink);
        setIsReadyDownload(true);
    };

    // Manage stepSets change
    const handleChangeStepSets = (e) => {
        const { value } = e.target;
        if (stepNum < value) {
            let form = [...inputStates];
            if (basicInfoInput.checkedLinear) {
                for (let i = stepNum; i < value; i++) {
                    form.push({ id: uuidv4(), stepID: '', stepIDCheck: false, funcsSettings: [{ fid: uuidv4(), funcName: '', funcP: '', funcNameCheck: false }] });
                };
                dispatchL({ type: 'UPDATE', data: form });
                setInputStates(form);
            } else {
                for (let i = stepNum; i < value; i++) {
                    form.push({ id: uuidv4(), stepNum: 1, pipeSegment_srcid: '', pipeSegmentID: '', stepID: '', pipeSegment_srcidCheck: false, pipeSegmentIDCheck: false, stepIDCheck: false, linearSettings: [{ id: uuidv4(), stepID: '', stepIDCheck: false, funcsSettings: [{ fid: uuidv4(), funcName: '', funcP: '', funcNameCheck: false }] }] });
                }
                dispatchB({ type: 'UPDATE', data: form });
                setInputStates(form);
            };
            setStepNum(value);
        } else if (stepNum > value && value >= 1) {
            let form = [...inputStates];
            for (let i = 0; i < stepNum - value; i++) {
                form.pop();
            };
            if (basicInfoInput.checkedLinear) {
                dispatchL({ type: 'UPDATE', data: form });
                setInputStates(form);
            } else {
                dispatchB({ type: 'UPDATE', data: form });
                setInputStates(form);
            };
            setStepNum(value);
        };
    };

    return (
        <div>
            <div style={{ float: 'center', margin: 30 }} >
                <Link className={classes.nav} to="/">Intro Page ᐊ</Link>
                <em>  /  </em>
                <Link className={classes.nav} to="/start"> Info Form ᐊ</Link>
            </div>
            <div>
                {activeStep === 0 ? (
                    <BasicInfo
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
                            <InputLabel > {basicInfoInput.checkedBranch ? 'pipeSegments' : 'stepSet number'}</InputLabel>
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
                        <h4>Code Preview</h4>                       
                        {isReadyDownload ? <ReviewPage codeString={codeString} /> : null}
                    </div>



                ) : <div>
                        <h4>Code Preview</h4>
                        {isReadyDownload ? <ReviewPage codeString={codeString} /> : null}
                    </div>

                }

            </div>
            <Steppers
                activeStep={activeStep}
                handleSubmit={handleSubmit}
                handleBack={handleBack}
                handleNext={handleNext}
                handleReset={handleReset}
                isReadyDownload={isReadyDownload}
                downloadLink={downloadLink}
            />

        </div>
    );




}