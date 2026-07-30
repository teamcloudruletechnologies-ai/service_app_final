import { useState, useEffect } from 'react';
import { complaintsAPI } from '../api';
import { toast } from 'react-toastify';

export default function Support() {
  const [complaints, setComplaints] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedComplaint, setSelectedComplaint] = useState(null);
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [notesInput, setNotesInput] = useState('');

  useEffect(() => {
    fetchComplaints();
  }, []);

  const fetchComplaints = async () => {
    try {
      setLoading(true);
      const res = await complaintsAPI.getAll();
      setComplaints(res.data?.rows || res.data?.data || res.data || []);
    } catch (err) {
      console.error('Failed to fetch complaints', err);
    } finally {
      setLoading(false);
    }
  };

  const openDrawer = (complaint) => {
    setSelectedComplaint(complaint);
    setNotesInput(complaint.admin_notes || '');
    setIsDrawerOpen(true);
  };

  const closeDrawer = () => {
    setIsDrawerOpen(false);
    setTimeout(() => {
      setSelectedComplaint(null);
      setNotesInput('');
    }, 300);
  };

  const handleStatusUpdate = async (newStatus) => {
    if (!selectedComplaint) return;
    try {
      await complaintsAPI.updateStatus(selectedComplaint.id, newStatus);
      await fetchComplaints();
      setSelectedComplaint(prev => ({ ...prev, status: newStatus }));
      toast.success(`Ticket status updated to ${newStatus}`);
    } catch (err) {
      toast.error(`Error updating status: ${err.message}`);
    }
  };

  const handleAddNotes = async () => {
    if (!selectedComplaint) return;
    try {
      await complaintsAPI.addNotes(selectedComplaint.id, notesInput);
      await fetchComplaints();
      setSelectedComplaint(prev => ({ ...prev, admin_notes: notesInput }));
      toast.success('Notes updated successfully');
    } catch (err) {
      toast.error(`Error adding notes: ${err.message}`);
    }
  };

  const getStatusBadge = (status) => {
    switch (status?.toLowerCase()) {
      case 'open':
        return <span className="px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800 border border-red-200">Open</span>;
      case 'under review':
      case 'under_review':
        return <span className="px-2.5 py-1 rounded-full text-xs font-medium bg-orange-100 text-orange-800 border border-orange-200">Under Review</span>;
      case 'in progress':
      case 'in_progress':
        return <span className="px-2.5 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800 border border-blue-200">In Progress</span>;
      case 'resolved':
      case 'closed':
        return <span className="px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 border border-green-200">{status}</span>;
      default:
        return <span className="px-2.5 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800 border border-gray-200">{status}</span>;
    }
  };

  return (
    <div className="flex-1 p-8 bg-gray-50 overflow-auto font-sans relative">
      <div className="max-w-6xl mx-auto">
        
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Complaints & Support</h1>
            <p className="text-sm text-gray-500 mt-1">Manage customer grievances, worker disputes, and support tickets.</p>
          </div>
        </div>

        {/* Table Container */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-200 text-xs uppercase tracking-wider text-gray-500">
                  <th className="px-6 py-4 font-semibold">Ticket ID</th>
                  <th className="px-6 py-4 font-semibold">Subject</th>
                  <th className="px-6 py-4 font-semibold">User Type</th>
                  <th className="px-6 py-4 font-semibold">Date</th>
                  <th className="px-6 py-4 font-semibold">Status</th>
                  <th className="px-6 py-4 font-semibold text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {loading ? (
                  <tr>
                    <td colSpan="6" className="px-6 py-12 text-center text-gray-500">
                      Loading complaints...
                    </td>
                  </tr>
                ) : complaints.length === 0 ? (
                  <tr>
                    <td colSpan="6" className="px-6 py-12 text-center text-gray-500">
                      No support tickets found.
                    </td>
                  </tr>
                ) : (
                  complaints.map((complaint) => (
                    <tr key={complaint.id} className="hover:bg-gray-50 transition-colors cursor-pointer" onClick={() => openDrawer(complaint)}>
                      <td className="px-6 py-4">
                        <div className="font-medium text-gray-900">#{complaint.id}</div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-sm text-gray-900 max-w-xs truncate">{complaint.subject || 'No Subject'}</div>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600 capitalize">
                        {complaint.raised_by_type || 'User'}
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">
                        {new Date(complaint.created_at).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4">
                        {getStatusBadge(complaint.status)}
                      </td>
                      <td className="px-6 py-4 text-right">
                        <button 
                          onClick={(e) => { e.stopPropagation(); openDrawer(complaint); }}
                          className="text-blue-600 hover:text-blue-800 text-sm font-medium"
                        >
                          View Ticket
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Drawer Overlay */}
      {isDrawerOpen && (
        <div 
          className="fixed inset-0 bg-black/20 backdrop-blur-sm z-40 transition-opacity"
          onClick={closeDrawer}
        ></div>
      )}

      {/* Side Drawer */}
      <div 
        className={`fixed top-0 right-0 h-full w-full max-w-md bg-white shadow-2xl z-50 transform transition-transform duration-300 ease-in-out flex flex-col ${isDrawerOpen ? 'translate-x-0' : 'translate-x-full'}`}
      >
        {selectedComplaint && (
          <>
            {/* Drawer Header */}
            <div className="flex items-center justify-between p-6 border-b border-gray-100">
              <div>
                <h2 className="text-xl font-bold text-gray-900">Ticket #{selectedComplaint.id}</h2>
                <div className="mt-2">{getStatusBadge(selectedComplaint.status)}</div>
              </div>
              <button 
                onClick={closeDrawer}
                className="text-gray-400 hover:text-gray-600 p-2 rounded-full hover:bg-gray-100 transition-colors"
              >
                ✕
              </button>
            </div>

            {/* Drawer Content */}
            <div className="flex-1 overflow-y-auto p-6 space-y-6">
              
              <div>
                <h4 className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-2">Complaint Details</h4>
                <div className="bg-gray-50 rounded-lg p-4 border border-gray-100">
                  <div className="font-medium text-gray-900 mb-2">{selectedComplaint.subject || 'No Subject'}</div>
                  <p className="text-sm text-gray-600 whitespace-pre-wrap">{selectedComplaint.description}</p>
                </div>
              </div>

              <div>
                <h4 className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-2">Involved Parties</h4>
                <div className="bg-gray-50 rounded-lg p-4 space-y-3 border border-gray-100">
                  <div className="flex justify-between">
                    <span className="text-sm text-gray-500">Raised By</span>
                    <span className="text-sm font-medium text-gray-900 capitalize">{selectedComplaint.raised_by_type} (ID: {selectedComplaint.raised_by_id})</span>
                  </div>
                  {selectedComplaint.booking_id && (
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-500">Related Booking</span>
                      <span className="text-sm font-medium text-gray-900">#{selectedComplaint.booking_id}</span>
                    </div>
                  )}
                  <div className="flex justify-between">
                    <span className="text-sm text-gray-500">Date</span>
                    <span className="text-sm font-medium text-gray-900">{new Date(selectedComplaint.created_at).toLocaleString()}</span>
                  </div>
                </div>
              </div>

              <div>
                <h4 className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-2">Admin Notes (Internal)</h4>
                <textarea
                  value={notesInput}
                  onChange={(e) => setNotesInput(e.target.value)}
                  placeholder="Add private notes for admins here..."
                  className="w-full h-24 p-3 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all"
                ></textarea>
                <button 
                  onClick={handleAddNotes}
                  className="mt-2 text-sm bg-gray-100 hover:bg-gray-200 text-gray-700 px-4 py-2 rounded-lg font-medium transition-colors"
                >
                  Save Notes
                </button>
              </div>

            </div>

            {/* Drawer Footer / Actions */}
            <div className="p-6 border-t border-gray-100 bg-gray-50">
              <h4 className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-3">Update Status</h4>
              <div className="grid grid-cols-2 gap-2">
                <button onClick={() => handleStatusUpdate('Open')} className={`py-2 rounded-lg text-sm font-medium border ${selectedComplaint.status?.toLowerCase() === 'open' ? 'bg-red-50 border-red-200 text-red-700' : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'}`}>Open</button>
                <button onClick={() => handleStatusUpdate('Under Review')} className={`py-2 rounded-lg text-sm font-medium border ${['under review', 'under_review'].includes(selectedComplaint.status?.toLowerCase()) ? 'bg-orange-50 border-orange-200 text-orange-700' : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'}`}>Under Review</button>
                <button onClick={() => handleStatusUpdate('In Progress')} className={`py-2 rounded-lg text-sm font-medium border ${['in progress', 'in_progress'].includes(selectedComplaint.status?.toLowerCase()) ? 'bg-blue-50 border-blue-200 text-blue-700' : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'}`}>In Progress</button>
                <button onClick={() => handleStatusUpdate('Resolved')} className={`py-2 rounded-lg text-sm font-medium border ${selectedComplaint.status?.toLowerCase() === 'resolved' ? 'bg-green-50 border-green-200 text-green-700' : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'}`}>Resolved</button>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
